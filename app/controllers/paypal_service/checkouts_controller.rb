=begin
PayPal Express is a multi-step process.

1. Craft an initial request to PayPal, indicating that you wish to send a
  customer to them to purchase an item. It includes various fields such as
  a list of items, order total, taxes, currency, return URLs, etc. PayPal will
  respond with a token that you need to use in future requests.

2. Send the user to PayPal along with the process token from the prior request.

3. The user completes their purchase and are redirected back to your site
  (along with the process token).

4. Look up the details for the token (another PayPal request) and verify that
  the PayPal process happened successfully.

5. Run the actual purchase request to PayPal, again verifying that it succeeded.
=end

class PaypalService::CheckoutsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def checkout
    # step 1
    if service.checkout
      # step 2
      return redirect_to service.redirect_url
    end
  end

  # Here we're returning from step 3
  def receipt
    if service.receipt
      return redirect_to person_transaction_path(person_id: service.starter.username, id: service.transaction.id)
    end
  end

  def cancel
  end

  def refund
    if service.refund

      return redirect_to person_transaction_path(person_id: service.starter.username, id: service.transaction.id)
    end
  end

  private

  def service
    @service = ActiveMerchantCheckout.new(community: @current_community, params: params, controller: self)
  end

  class ActiveMerchantCheckout
    class Failure < StandardError; end

    attr_reader :community, :params, :controller, :token, :error_message

    def initialize(community:, params:, controller:)
      @community = community
      @params = params
      @controller = controller
    end

    def checkout
      unless transaction.present? || paypal_soap_account_present?
        return false
      end

      payment
      response = paypal_gateway.setup_purchase(
        transaction.total_cents,
        order_paypal_params.merge(
          return_url: controller.receipt_paypal_service_checkout_url(transaction),
          cancel_return_url: controller.receipt_paypal_service_checkout_url(transaction),
        )
      )

      if response.success?
        @token = response.token
        payment.update(
          correlation_id: response.params["CorrelationID"],
          token: token
        )
        MarketplaceService::Transaction::Command.transition_to(transaction.id, :pending)
      else
        logger.error("PAYPAL ERROR: #{response.params['Errors']}")
      end

      return response.success?
    end

    def redirect_url
      paypal_gateway.redirect_url_for(payment.token)
    end

    def receipt
      unless transaction.present? || paypal_soap_account_present?
        return false
      end

      transaction_by_token
      payment = transaction.paypal_payment

      if payment.payment_status == 'completed'
        raise Failure.new("This order has already been paid for, no further action is necessary")
      end

      # Here's step 4
      purchase_details = paypal_gateway.details_for(params[:token])
      unless purchase_details.success?
        raise Failure.new(purchase_details.message)
      end

      # Finally, step 5
      purchase_response = paypal_gateway.purchase(
        transaction.total_cents,
        order_paypal_params.merge(
          token: params[:token],
          payer_id: purchase_details.payer_id,
        )
      )

      unless purchase_response.success?
        raise Failure.new(purchase_response.message)
      end

      payment.update(
        payment_status: 'completed',
        #  payment_id                 :string(64)
        #  payment_date               :datetime
        payment_total_cents:  transaction.total_cents,
        paypal_transaction_id: purchase_response.params["PaymentInfo"]["TransactionID"],
      )
      MarketplaceService::Transaction::Command.transition_to(transaction.id, :paid)
      MarketplaceService::Transaction::Command.transition_to(transaction.id, :confirmed)

      true
    rescue Failure => e
      @error_message = e.message
      logger.error("PAYPAL ERROR: #{e.message}")
      false
    end

    def refund
      unless transaction.present? || paypal_soap_account_present?
        return false
      end

      payment_to_refund = transaction.paypal_payment
      return false unless payment_to_refund&.completed?

      amount = (params[:amount].to_f * 100).to_i
      partial_refund = payment_to_refund.payment_total_cents > amount
      response = paypal_gateway.refund(amount, payment_to_refund.paypal_transaction_id)

      unless response.success?
        raise Failure.new(response.message)
      end

      response.params
      payment_to_refund.update(
        payment_status: 'refunded',
        paypal_refund_transaction_id: response.params["refund_transaction_id"],
        refund_total_cents: response.params["gross_refund_amount"].to_f * 100,
        refund_fee_total_cents: response.params["fee_refund_amount"].to_f * 100,
      )
      notice =
        if partial_refund
          I18n.t("refund.cancel_partial",
            amount: MoneyViewUtils.to_humanized(payment_to_refund.refund_total),
            total: MoneyViewUtils.to_humanized(payment_to_refund.payment_total))
        else
          I18n.t("refund.cancel_full", amount: MoneyViewUtils.to_humanized(payment_to_refund.refund_total))
        end
      message = Message.new(
        conversation_id: transaction.conversation_id,
        sender_id: transaction.author.id,
        content: notice)
      message.save
      MessageSentJob.perform_later(message.id, community.id)
      MarketplaceService::Transaction::Command.transition_to(transaction.id, :rejected, nil)
      SendCancelReceipt.perform_later(transaction.id)
    rescue Failure => e
      @error_message = e.message
      logger.error("PAYPAL ERROR: #{e.message}")
      false
    end

    def transaction
      @transaction ||= Transaction.find(params[:id])
    end

    def starter
      transaction.starter
    end

    def transaction_by_token
      @transaction = Transaction.by_paypal_token(params[:token]).first
    end

    def order_paypal_params
      {
        items: [{
          name: transaction.listing_title,
          quantity: 1,
          amount: transaction.total_cents,
          description: description,
        }],
        ip: controller.request.remote_ip,
        allow_guest_checkout: true,
        currency: transaction.unit_price_currency,
        invoice_id: transaction.id,
      }
    end

    def description
      result = "#{starter&.display_name} "
      result += description_booking
      result += description_fields
      result
    end

    def description_booking
      result = ""

      if booking = transaction.booking
        duration = booking.duration
        start_time = booking.start_time
        end_time = booking.end_time
        result = ""
        result += I18n.t('transactions.initiate.booked_hours_label', count: duration)
        result += I18n.l(start_time.to_date, format: :long_with_abbr_day_name)
        result += ' - '
        result += I18n.t("transactions.initiate.start_end_time",
              start_time: I18n.l(start_time, format: :hours_only),
              end_time: I18n.l(end_time, format: :hours_only))
        result += I18n.t("transactions.initiate.duration_in_hours", count: duration)
      end

      result
    end

    def description_fields
      result = ""

      transaction.fields.each do |field|
        result += "#{field.title} #{field.to_s}"
      end

      result
    end

    def paypal_gateway
      @paypal_gateway ||= ActiveMerchant::Billing::PaypalExpressGateway.new(
        login: paypal_soap_account.login,
        password: paypal_soap_account.password,
        signature: paypal_soap_account.signature,
      )
    end

    def payment
      return transaction.paypal_payment if transaction.paypal_payment

      payment_params = {
        community_id: community.id,
        tx: transaction,
        payer: transaction.starter,
        receiver: transaction.listing.author,
        currency: transaction.unit_price_currency,
        payment_status: "pending",
        commission_status: "not_charged",
        merchant_id: "none",
      }
      transaction.create_paypal_payment(payment_params)
    end

    def paypal_soap_account
      @paypal_soap_account ||= transaction.listing.author.paypal_soap_account
    end

    def paypal_soap_account_present?
      paypal_soap_account.present? && paypal_soap_account.persisted?
    end

    def logger
      Rails.logger
    end
  end
end
