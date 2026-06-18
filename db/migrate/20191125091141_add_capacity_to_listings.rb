class AddCapacityToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :capacity, :integer, default: 1
  end
end
