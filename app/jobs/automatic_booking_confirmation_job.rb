class AutomaticBookingConfirmationJob < ApplicationJob
  # :conversation_id should be :transaction_id, but can not be easily migrated due to existing job descriptions in DB
  
  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(conversation_id, current_user_id, community_id)
    community = Community.find(community_id)
    transaction = Transaction.find(conversation_id)

    if MarketplaceService::Transaction::Query.can_transition_to?(transaction.id, :confirmed)
      MarketplaceService::Transaction::Command.transition_to(transaction.id, :confirmed)
      MailCarrier.deliver_now(PersonMailer.booking_transaction_automatically_confirmed(transaction, community))
    end
  end

end
