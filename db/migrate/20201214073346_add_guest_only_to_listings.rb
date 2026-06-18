class AddGuestOnlyToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :guest_only, :boolean, default: false
  end
end
