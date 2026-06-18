class TwilioSmsJob < ApplicationJob
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.first)
  end

  def perform(community_id, user_id, message)
    community   = Community.find(community_id)
    account_sid = APP_CONFIG.twilio_sid
    auth_token  = APP_CONFIG.twilio_token
    from        = APP_CONFIG.twilio_from
    client = Twilio::REST::Client.new account_sid, auth_token
    user = Person.where(id: user_id, community_id: community_id).first
    phone_number = (user && user.phone_number.present? ? user.phone_number : "").gsub(/[^0-9]/,'')
    if phone_number.present?
      client.messages.create({body: message, from: from, to: "+"+phone_number})
    end
  end
end
