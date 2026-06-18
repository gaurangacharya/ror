class AddRestaurantToListing < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :restaurant, :boolean, default: false
    add_column :listings, :restaurant_price, :integer, default: 0
  end
end
