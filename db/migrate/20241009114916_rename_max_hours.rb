class RenameMaxHours < ActiveRecord::Migration[5.2]
  def change
    rename_column :listing_working_time_slots, :max_hours, :max_capacity
  end
end
