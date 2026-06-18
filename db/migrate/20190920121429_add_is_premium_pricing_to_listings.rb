class AddIsPremiumPricingToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :affiliate_pricing, :boolean, default: true
  end
end
