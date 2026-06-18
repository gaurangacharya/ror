class FixListingAddOnsCurrency < ActiveRecord::Migration[6.1]
  def up
    ListingAddOn.includes(:listing).find_each do |add_on|
      if add_on.listing && add_on.currency != add_on.listing.currency
        add_on.update_columns(currency: add_on.listing.currency)
      end
    end
  end

  def down
  end
end
