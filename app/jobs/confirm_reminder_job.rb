class ConfirmReminderJob < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(conversation_id, recipient_id, community_id, days_to_cancel)
    return if Maybe(::PlanService::API::Api.plans.get_current(community_id: community_id).data)[:expired].or_else(false)

    transaction = Transaction.find(conversation_id)
    community = Community.find(community_id)
    if transaction.status.eql?("paid")
      MailCarrier.deliver_now(PersonMailer.send("confirm_reminder", transaction, transaction.buyer, community, days_to_cancel))
    end
  end

end
