module StripeService::API
  class Payments
    class << self
      PaymentStore = StripeService::Store::StripePayment

      TransactionStore = TransactionService::Store::Transaction

      def create_preauth_payment(tx, gateway_fields)
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        if !seller_account || !seller_account[:stripe_seller_id].present?
          return Result::Error.new("No Seller Account")
        end

        payer_account = create_or_update_payer(tx[:community_id], tx[:starter_id], gateway_fields)

        customer_id   = payer_account[:stripe_customer_id]
        seller_id     = seller_account[:stripe_seller_id]

        case stripe_api.charges_mode(tx[:community_id])
        when :separate, :destination
          source_id  = payer_account[:stripe_customer_id]
        when :direct
          source_id  = stripe_api.create_token(community: tx[:community_id], customer_id: customer_id, account_id: seller_id).id
        end

        subtotal   = order_total(tx)
        total      = subtotal
        commission = order_commission(tx)
        fee        = Money.new(0, subtotal.currency)

        description = "Payment #{tx[:id]} for #{tx[:listing_title]} via #{gateway_fields[:service_name]} "
        metadata = {
          sharetribe_transaction_id: tx[:id],
          sharetribe_seller_id: tx[:listing_author_id],
          sharetribe_payer_id: tx[:starter_id],
          sharetribe_mode: stripe_api.charges_mode(tx[:community_id])
        }
        stripe_charge = stripe_api.charge(
          community: tx[:community_id],
          token: source_id,
          seller_account_id: seller_id,
          amount: total.cents,
          fee: commission.cents,
          currency: total.currency.iso_code,
          description: description,
          metadata: metadata)

        payment = PaymentStore.create(tx[:community_id], tx[:id], {
          payer_id: tx[:starter_id],
          receiver_id: tx[:listing_author_id],
          currency: tx[:unit_price].currency.iso_code,
          sum_cents: total.cents,
          commission_cents: commission.cents,
          fee_cents: fee.cents,
          subtotal_cents: subtotal.cents,
          stripe_charge_id: stripe_charge.id
        })

        if gateway_fields[:shipping_address].present?
          TransactionStore.upsert_shipping_address(
            community_id: tx[:community_id],
            transaction_id: tx[:id],
            addr: gateway_fields[:shipping_address])
        end

        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def cancel_preauth(tx, reason)
        payment = PaymentStore.get(tx[:community_id], tx[:id])
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        stripe_api.cancel_charge(
          community: tx[:community_id],
          charge_id: payment[:stripe_charge_id],
          account_id: seller_account[:stripe_seller_id],
          reason: reason,
          metadata: {sharetribe_transaction_id: tx[:id]}
        )
        payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id], data: {status: 'canceled'})
        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def cancel_with_refund(tx, amount)
        payment = PaymentStore.get(tx[:community_id], tx[:id])
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        refund = stripe_api.cancel_charge(
          community: tx[:community_id],
          charge_id: payment[:stripe_charge_id],
          account_id: seller_account[:stripe_seller_id],
          reason: 'requested_by_customer',
          metadata: {sharetribe_transaction_id: tx[:id]},
          amount: amount
        )
        payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id], data: {status: 'refunded', refund_id: refund.id, refund_amount_cents: amount, is_refunded: true})
        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def capture(tx)
        payment = PaymentStore.get(tx[:community_id], tx[:id])
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        charge = stripe_api.capture_charge(community: tx[:community_id], charge_id: payment[:stripe_charge_id], seller_id: seller_account[:stripe_seller_id])
        balance_txn = stripe_api.get_balance_txn(community: tx[:community_id], balance_txn_id: charge.balance_transaction, account_id: seller_account[:stripe_seller_id])
        payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id],
                                      data: {
                                        status: 'paid',
                                        real_fee_cents: balance_txn.fee,
                                        available_on: Time.zone.at(balance_txn.available_on)
                                      })
        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def payment_details(tx)
        payment = PaymentStore.get(tx[:community_id], tx[:transaction_id] || tx[:id])
        unless payment
          total      = order_total(tx)
          commission = order_commission(tx)
          fee        = Money.new(0, total.currency)
          payment = {
            sum: total,
            commission: commission,
            real_fee: fee,
            subtotal: total - fee,
          }
        end

        # in case of :destination payments, gateway fee is always charged from admin account, we cannot know it upfront, as transfer to seller = total - commission, is immediate
        # in case of :direct payments, gateway fee is charged from seller account, and visible in balance transaction
        # in case of :separate payments, gateway fee is charged from admin account, but then deducted from seller on delayed transfer
        gateway_fee = if stripe_api.charges_mode(tx[:community_id]) == :destination
            Money.new(0, payment[:sum].currency)
          elsif stripe_api.charges_mode(tx[:community_id]) == :direct
            payment[:real_fee] ? payment[:real_fee] - payment[:commission] : Money.new(0, payment[:sum].currency)
          else
            payment[:real_fee]
          end
        {
          payment_total:       payment[:sum],
          total_price:         payment[:subtotal],
          charged_commission:  payment[:commission],
          payment_gateway_fee: gateway_fee
        }
      end

      def payout(tx)
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        payment = PaymentStore.get(tx[:community_id], tx[:id])

        seller_gets = payment[:subtotal] - payment[:commission]

        case stripe_api.charges_mode(tx[:community_id])
        when :separate
          seller_gets -= payment[:real_fee] || 0
          if seller_gets > 0
            result = stripe_api.perform_transfer(
              community: tx[:community_id],
              account_id: seller_account[:stripe_seller_id],
              amount_cents: seller_gets.cents,
              currency: payment[:sum].currency,
              initial_amount: payment[:subtotal].cents,
              charge_id: payment[:stripe_charge_id],
              metadata: {sharetribe_transaction_id: tx[:id]}
            )
          end
        when :direct
          if seller_gets > 0 && seller_account[:account_type] != 'connect'
            result = stripe_api.perform_payout(
              community: tx[:community_id],
              account_id: seller_account[:stripe_seller_id],
              amount_cents: seller_gets.cents,
              currency: payment[:sum].currency,
              metadata: {shretribe_order_id: tx[:id]}
            )
          end
        when :destination
          if seller_gets > 0
            charge = stripe_api.get_charge(community: tx[:community_id], charge_id: payment[:stripe_charge_id])
            transfer = stripe_api.get_transfer(community: tx[:community_id], transfer_id: charge.transfer)
            result = stripe_api.perform_payout(
              community: tx[:community_id],
              account_id: seller_account[:stripe_seller_id],
              amount_cents: transfer.amount,
              currency: transfer.currency,
              metadata: {shretribe_order_id: tx[:id]}
            )
          end
        end

        author = Person.find(tx[:listing_author_id])
        buyer  = Person.find(tx[:starter_id])
        community = Community.find(tx[:community_id])
        tx_model = ::Transaction.find(tx[:id])
        referral_id = tx_model.user_by_ref_id

        if author.is_affiliate? && (buyer.is_hotel? || buyer.is_hotel_guest? || referral_id) && payment[:commission] > 0
          own_affiliate = buyer.hotel && referral_id.present? && referral_id == buyer.hotel.id
          reseller_percent = buyer.is_hotel? || buyer.is_hotel_guest? && !own_affiliate ? community.hotel_percent_user : community.hotel_percent_guest
          platform_percent = buyer.is_hotel? || buyer.is_hotel_guest? && !own_affiliate ? community.hotel_percent_platform : community.platform_percent_guest
          hotel_gets = payment[:commission] * reseller_percent.to_f / (reseller_percent + platform_percent)
          reseller_id = buyer.is_hotel_guest? ? buyer.hotel_id : buyer.id
          reseller_id = referral_id || reseller_id
          hotel_account = accounts_api.get(community_id: tx[:community_id], person_id: reseller_id).data

          if hotel_account && hotel_account[:stripe_seller_id]
            result = stripe_api.perform_simple_transfer(
                community: tx[:community_id],
                account_id: hotel_account[:stripe_seller_id],
                amount_cents: hotel_gets.cents,
                amount_currency: payment[:sum].currency,
                charge_id: nil)
          end
        end

        payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id],
                                      data: {
                                        status: 'transfered',
                                        stripe_transfer_id: seller_gets > 0 && result ? result.id : "ZERO",
                                        transfered_at: Time.zone.now
                                      })
        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def stripe_api
        StripeService::API::Api.wrapper
      end

      def accounts_api
        StripeService::API::Api.accounts
      end

      def create_or_update_payer(community_id, person_id, gateway_fields)
        payer_account     = accounts_api.get(community_id: community_id, person_id: person_id).data
        if gateway_fields[:stripe_token].present?
          unless payer_account
            payer_account = accounts_api.create_customer(community_id: community_id, person_id: person_id, body: {}).data
          end

          if payer_account[:stripe_customer_id].present?
            stripe_customer = stripe_api.update_customer(
              community: community_id,
              customer_id: payer_account[:stripe_customer_id],
              token: gateway_fields[:stripe_token]
            )
          else
            stripe_customer = stripe_api.register_customer(
              community: community_id,
              email: gateway_fields[:stripe_email],
              card_token: gateway_fields[:stripe_token],
              metadata: {sharetribe_person_id: person_id}
            )
            accounts_api.update_field(community_id: community_id, person_id: person_id, field: :stripe_customer_id, value: stripe_customer.id)
          end
        end
        accounts_api.get(community_id: community_id, person_id: person_id).data
      end

      def order_total(tx)
        Transaction.find(tx[:id]).total
      end

      def order_commission(tx)
        TransactionService::Transaction.calculate_commission(tx[:unit_price] * tx[:listing_quantity], tx[:commission_from_seller], tx[:minimum_commission])
      end

      def cancel_deposit(tx, reason, amount = nil)
        payment = PaymentStore.get(tx[:community_id], tx[:id], true)
        return Result::Success.new("No deposit") if payment.nil?
        return Result::Success.new("Already refunded") if payment[:is_refunded]

        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        amount ||= tx.deposit.cents
        if tx.deposit.cents == amount
          refund = stripe_api.cancel_external_charge(
            community: tx[:community_id],
            charge_id: payment[:stripe_charge_id],
            seller_id: seller_account[:stripe_seller_id]
          )
          payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id], is_deposit: true,
                                        data: {status: 'refunded', is_refunded: true, refund_id: refund.id, refund_amount_cents: amount})
        else
          charge_amount = tx.deposit.cents - amount
          charge = stripe_api.capture_external_charge(
            community: tx[:community_id],
            charge_id: payment[:stripe_charge_id],
            seller_id: seller_account[:stripe_seller_id],
            amount: charge_amount)
          payment = PaymentStore.update(transaction_id: tx[:id], community_id: tx[:community_id], is_deposit: true,
                                        data: {status: 'refunded', is_refunded: true, refund_id: charge.id, refund_amount_cents: amount})
        end
        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def create_preauth_deposit(tx, gateway_fields)
        seller_account = accounts_api.get(community_id: tx[:community_id], person_id: tx[:listing_author_id]).data
        if !seller_account || !seller_account[:stripe_seller_id].present?
          return Result::Error.new("No Seller Account")
        end
        unless tx[:deposit].present? && tx[:deposit] > 0
          return Result::Success.new("No deposit")
        end

        seller_id  = seller_account[:stripe_seller_id]
        source_id  = stripe_api.create_token(community: tx[:community_id], customer_id: gateway_fields[:stripe_customer_id], account_id: seller_id).id

        total   = tx[:deposit]

        description = "Deposit #{tx[:id]} for #{tx[:listing_title]} via #{gateway_fields[:service_name]} "
        metadata = {
          sharetribe_transaction_id: tx[:id],
          sharetribe_seller_id: tx[:listing_author_id],
          sharetribe_payer_id: tx[:starter_id],
          sharetribe_mode: stripe_api.charges_mode(tx[:community_id])
        }
        stripe_charge = stripe_api.charge(
          community: tx[:community_id],
          token: source_id,
          seller_account_id: seller_id,
          amount: total.cents,
          fee: 0,
          currency: total.currency.iso_code,
          description: description,
          metadata: metadata)

        payment = PaymentStore.create(tx[:community_id], tx[:id], {
          payer_id: tx[:starter_id],
          receiver_id: tx[:listing_author_id],
          currency: total.currency.iso_code,
          sum_cents: total.cents,
          commission_cents: 0,
          fee_cents: 0,
          subtotal_cents: total.cents,
          stripe_charge_id: stripe_charge.id
        }, true)

        Result::Success.new(payment)
      rescue => e
        log_error(e)
        Result::Error.new(e.message)
      end

      def log_error(e)
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
