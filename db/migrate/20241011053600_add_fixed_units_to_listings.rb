class AddFixedUnitsToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :fixed_units, :float
  end
end
