class AddIndexesToBookingsAndSlots < ActiveRecord::Migration[5.1]
  def change
    # speedup slots for given intervals
    add_index "listing_working_time_slots", [:calendar, :start_time, :end_time, :listing_id], name: 'index_working_time_slots_on_start_end_time'

    # spedup bookings for given intervals
    add_index :bookings, [:start_time, :end_time], name: 'index_bookings_on_start_end_time'

    # binary masks for booked hours on day
    add_column :bookings, :binary_mask, :integer, limit: 8, default: 0

    # binary masks for working hours on day
    add_column :listing_working_time_slots, :binary_mask, :integer, limit: 8, default: 0

    # speedup group by listing_id when querying bookings, as MySQL often creates filesort for that, as listing_id is in another joined table transactions
    add_column :bookings, :listing_id, :integer
  end
end
