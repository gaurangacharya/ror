class AddIndexOnBookingsListingIdAndStartTime < ActiveRecord::Migration[5.1]
  def change
    add_index :bookings, [:listing_id, :start_time]
  end
end
