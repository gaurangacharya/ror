class ListingUpdatedJob < ApplicationJob
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(listing_id, community_id)
    listing = Listing.find(listing_id)
    community = Community.find(community_id)
    listing.notify_followers(community, listing.author, true)
  end
end
