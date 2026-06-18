class AddMinQuantiyToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :min_quantity, :integer, default: 1
    add_column :listings, :max_quantity, :integer, default: nil
  end
end
