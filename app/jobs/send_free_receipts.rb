class SendFreeReceipts < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community_id)
  end

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    receipt_to_seller = seller_should_receive_receipt(transaction.listing_author_id)

    message = I18n.t("twilio.transaction_free", transaction_id: transaction_id)
    TwilioSmsJob.set(priority: 9).perform_later(transaction.community_id, transaction.starter_id, message)

    if seller_should_receive_receipt(transaction.listing_author_id)
      TransactionMailer.free_receipt_to_seller(transaction).deliver_now
    end
    TransactionMailer.free_receipt_to_buyer(transaction).deliver_now
  end

  private

  def seller_should_receive_receipt(seller_id)
    Person.find(seller_id).should_receive?("email_about_new_payments")
  end

end
