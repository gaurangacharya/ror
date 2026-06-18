class AddIndexToTimeSlotsOnListingAndStartTime < ActiveRecord::Migration[5.1]
  def change
    add_index :listing_working_time_slots, [:listing_id, :start_time, :end_time], name: 'index_listing_and_time'
  end
end
