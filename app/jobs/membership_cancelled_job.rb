class MembershipCancelledJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(person_id, community_id)
    community = Community.find(community_id)
    user = Person.find(person_id)
    MailCarrier.deliver_now(PersonMailer.membership_cancelled(user, community))
    community.admins.each do |admin|
      next unless admin.confirmed_notification_emails_to.present?
      MailCarrier.deliver_now(PersonMailer.membership_cancelled_admin(admin, user, community))
    end
  end
end
