class CommunityJoinedJob < ApplicationJob
  include DelayedSentryNotification
  queue_as :mailers

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(person_id, community_id)
    new_member = Person.find(person_id)
    community = Community.find(community_id)

    if community.email_admins_about_new_members?
      community.admins.each do |admin|
        email = PersonMailer.new_member_notification(new_member, community, admin)
        if email.present?
          MailCarrier.deliver_now(email)
        end
      end
    end
  end

end
