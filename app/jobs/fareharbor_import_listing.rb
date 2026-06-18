class FareharborImportListing < ApplicationJob
  include DelayedSentryNotification

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.first)
  end

  def perform(community_id, listing_id)
    listing = ::Listing.find(listing_id)
    listing.update_from_fareharbor_item!
  end
end
