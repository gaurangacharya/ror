class TransactionCanceledJob < ApplicationJob
  include DelayedSentryNotification

  queue_as :transactions

  # This before hook should be included in all Jobs to make sure that the service_name is
  # correct as it's stored in the thread and the same thread handles many different communities
  # if the job doesn't have host parameter, should call the method with nil, to set the default service_name
  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(transaction_id, community_id)
    begin
      transaction = Transaction.find(transaction_id)
      community = Community.find(community_id)
      MailCarrier.deliver_now(PersonMailer.transaction_confirmed(transaction, community))
    rescue => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  end

end
