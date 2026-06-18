# == Schema Information
#
# Table name: listing_add_ons
#
#  id          :bigint           not null, primary key
#  listing_id  :bigint
#  title       :string(255)
#  price_cents :integer
#  currency    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_listing_add_ons_on_listing_id  (listing_id)
#

class ListingAddOn < ApplicationRecord
  belongs_to :listing
  before_validation :set_currency_from_listing, if: -> { listing.present? }

  monetize :price_cents, allow_nil: true, with_model_currency: :currency

  def price_for_user(person)
    if person&.premium_pricing?(listing)
      return price / 2
    end

    price
  end

  def set_currency_from_listing
    self.currency = listing.currency
  end
end
