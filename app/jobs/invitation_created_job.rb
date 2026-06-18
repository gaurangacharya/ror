class InvitationCreatedJob < ApplicationJob

  include DelayedSentryNotification

  queue_as :mailers

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(invitation_id, community_id)
    invitation = Invitation.find(invitation_id)
    MailCarrier.deliver_now(PersonMailer.invitation_to_kassi(invitation))
  end

end
