class AddHotelPercentGuestToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :hotel_percent_guest, :integer, default: 5
  end
end
