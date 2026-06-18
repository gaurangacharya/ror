class AddQuarterHourToListings < ActiveRecord::Migration[5.2]
  def change
    add_column :listings, :slot_15min_increment, :boolean
  end
end
