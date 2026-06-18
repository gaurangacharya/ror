class AddDescriptionToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :description_from_provider, :mediumtext
    add_column :listings, :description_closing, :mediumtext
  end
end
