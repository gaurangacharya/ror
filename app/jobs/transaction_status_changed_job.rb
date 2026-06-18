class TransactionStatusChangedJob < ApplicationJob
  include DelayedSentryNotification

  queue_as :transactions

  # This before hook should be included in all Jobs to make sure that the service_name is
  # correct as it's stored in the thread and the same thread handles many different communities
  # if the job doesn't have host parameter, should call the method with nil, to set the default service_name
  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(conversation_id, current_user_id, community_id, metadata = {})
    community = Community.find(community_id)
    transaction = Transaction.find(conversation_id)
    current_user = Person.find(current_user_id)
    buyer = transaction.other_party(current_user)
    if buyer.guest? || buyer.should_receive?("email_when_conversation_#{transaction.status}")
      MailCarrier.deliver_now(PersonMailer.conversation_status_changed(transaction, community, metadata))
    end
  end
end
