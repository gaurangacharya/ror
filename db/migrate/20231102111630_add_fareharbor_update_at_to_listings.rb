class AddFareharborUpdateAtToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :fareharbor_updated_at, :datetime
  end
end
