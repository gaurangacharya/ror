class AddPerDayFlagToListingWorkingTimeSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :listing_working_time_slots, :per_day, :boolean, default: false
  end
end
