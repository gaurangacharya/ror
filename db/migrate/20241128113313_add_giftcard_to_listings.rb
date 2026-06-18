class AddGiftcardToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :gift_card, :boolean, default: false
  end
end
