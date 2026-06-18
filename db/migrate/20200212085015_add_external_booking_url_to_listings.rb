class AddExternalBookingUrlToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :ext_booking_url, :string, limit: 1024
  end
end
