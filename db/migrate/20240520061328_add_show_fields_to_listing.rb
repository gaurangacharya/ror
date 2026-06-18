class AddShowFieldsToListing < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :show_min_quantity, :boolean, default: true
    add_column :listings, :show_max_quantity, :boolean, default: true
  end
end
