class TransactionPreauthorizedJob < ApplicationJob
  include DelayedSentryNotification

  queue_as :transactions

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    transaction = Transaction.find(arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community.id)
  end

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)
    MailCarrier.deliver_now(TransactionMailer.transaction_preauthorized(transaction)) unless transaction.auto_confirm?
  end
end
