class AddBookingDatesToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :booking_start, :string
    add_column :people, :booking_end, :string
    add_column :people, :booking_date, :string
  end
end
