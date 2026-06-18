class SendBookingChangedReceipt < ApplicationJob
  include DelayedSentryNotification

  queue_as :transactions

  before_perform do |job|
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community_id)
  end

  def perform(transaction_id, sender_id)
    transaction = Transaction.find(transaction_id)
    sender_is_buyer = transaction.starter_id == sender_id
    TransactionMailer.booking_changed(transaction, sender_is_buyer).deliver_now
  end

end
