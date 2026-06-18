class ListingCreatedJob < ApplicationJob
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(listing_id, community_id)
    listing = Listing.find(listing_id)
    community = Community.find(community_id)
    # Send reminder about missing payment information
    if MarketplaceService::Listing::Entity.send_payment_settings_reminder?(listing_id, community_id)
      MailCarrier.deliver_now(PersonMailer.payment_settings_reminder(listing, listing.author, community))
    end
  end

end
