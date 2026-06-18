class AddHidePriceToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :hide_price, :boolean, default: false
  end
end
