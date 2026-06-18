class AddStartEndToWorkingTimeSlots < ActiveRecord::Migration[5.1]
  def change
    add_column :listing_working_time_slots, :start_time, :datetime
    add_column :listing_working_time_slots, :end_time, :datetime
    add_column :listing_working_time_slots, :calendar, :boolean, default: false
  end
end
