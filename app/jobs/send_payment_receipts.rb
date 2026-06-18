class SendPaymentReceipts < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community_id)
  end

  def perform(transaction_id)
    transaction = TransactionService::Transaction.query(transaction_id)
    receipt_to_seller = seller_should_receive_receipt(transaction[:listing_author_id])

    amount = MoneyViewUtils.to_humanized(transaction[:payment_total])
    TwilioSmsJob.set(priority: 9).perform_later(transaction[:community_id], transaction[:starter_id], I18n.t("twilio.transaction_paid", amount: amount, transaction_id: transaction_id))

    receipts =
      case transaction[:payment_gateway]

      when :paypal, :stripe
        community = Community.find(transaction[:community_id])

        receipts = []
        receipts << TransactionMailer.payment_receipt_to_seller(transaction) if receipt_to_seller
        receipts << TransactionMailer.payment_receipt_to_buyer(transaction)
        receipts

      else
        []
      end

    receipts.each { |receipt_mail| MailCarrier.deliver_now(receipt_mail) }
  end

  private

  def seller_should_receive_receipt(seller_id)
    Person.find(seller_id).should_receive?("email_about_new_payments")
  end

end
