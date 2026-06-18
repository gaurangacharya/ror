class AddBookingModeToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :booking_mode, :string, default: 'none' # none, hour, day, night
    add_column :listings, :min_units, :float, default: 1 
  end
end
