class AddInstantBookingFieldToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :instant_booking, :boolean, default: false
  end
end
