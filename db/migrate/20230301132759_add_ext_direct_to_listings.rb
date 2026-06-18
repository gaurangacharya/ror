class AddExtDirectToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :ext_booking_url_direct, :boolean, default: false
  end
end
