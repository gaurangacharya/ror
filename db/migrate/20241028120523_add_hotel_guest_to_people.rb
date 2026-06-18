class AddHotelGuestToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :hotel_guest, :boolean, default: false
  end
end
