class AddCallForPriceFieldToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :call_for_price, :boolean, default: false
  end
end
