class ReprocessListingImageJob < ApplicationJob

  include DelayedSentryNotification

  def perform(listing_image_id, style)
    listing_image = ListingImage.find_by_id(listing_image_id)
    return unless listing_image

    listing_image.image.reprocess_without_delay! style.to_sym
  end
end
