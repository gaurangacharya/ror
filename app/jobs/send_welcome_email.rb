class SendWelcomeEmail < ApplicationJob

  include DelayedSentryNotification

  queue_as :mailers

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(person_id, community_id)
    person = Person.find(person_id)
    community = Community.find(community_id)

    MailCarrier.deliver_now(PersonMailer.welcome_email(person, community))
  end

end
