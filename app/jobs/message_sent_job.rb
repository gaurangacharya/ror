class MessageSentJob < ApplicationJob

  include DelayedSentryNotification

  queue_as :mailers

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(last_message_id, community_id)
    message = Message.find(last_message_id)
    community = Community.find(community_id)
    message.send_email_to_participants(community)
  end

end
