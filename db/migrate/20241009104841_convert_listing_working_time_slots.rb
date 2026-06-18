class ConvertListingWorkingTimeSlots < ActiveRecord::Migration[5.2]
  def up
    change_column :listing_working_time_slots, :binary_mask, :decimal, precision: 40, scale: 0, default: 0
    change_column :listing_working_time_slots, :booked_mask, :decimal, precision: 40, scale: 0, default: 0
    change_column :listing_working_time_slots, :available_mask, :decimal, precision: 40, scale: 0, default: 0
  end

  def down
    change_column :listing_working_time_slots, :binary_mask, :integer, default: 0
    change_column :listing_working_time_slots, :booked_mask, :integer, default: 0
    change_column :listing_working_time_slots, :available_mask, :integer, default: 0
  end
end
