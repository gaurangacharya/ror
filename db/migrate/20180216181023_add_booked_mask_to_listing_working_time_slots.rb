class AddBookedMaskToListingWorkingTimeSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :listing_working_time_slots, :booked_mask, :integer, limit: 8, default: 0
    add_column :listing_working_time_slots, :available_mask,  :integer, limit: 8, default: 0
    add_column :listing_working_time_slots, :max_hours,   :integer, default: 0
  end
end
