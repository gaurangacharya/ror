class CommunityMemberEmailSentJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(sender_id, recipient_id, community_id, subject, content, locale)
    sender = Person.where(id: sender_id).first
    recipient = Person.where(id: recipient_id).first
    community = Community.where(id: community_id).first
    PersonMailer.community_member_email_from_admin(sender, recipient, community, subject, content, locale)
  end

end
