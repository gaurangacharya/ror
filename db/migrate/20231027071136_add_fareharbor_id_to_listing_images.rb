class AddFareharborIdToListingImages < ActiveRecord::Migration[5.1]
  def change
    add_column :listing_images, :fareharbor_id, :string
    add_index :listing_images, :fareharbor_id
  end
end
