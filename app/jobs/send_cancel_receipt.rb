class SendCancelReceipt < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community.id)
  end

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    MailCarrier.deliver_now(TransactionMailer.cancel_receipt_to_buyer(transaction))
  end

end
