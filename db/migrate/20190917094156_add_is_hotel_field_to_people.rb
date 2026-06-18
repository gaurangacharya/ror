class AddIsHotelFieldToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :is_hotel, :boolean, default: false
    add_column :communities, :hotel_percent_platform, :float, default: 10.0
    add_column :communities, :hotel_percent_user, :float, default: 5.0
    add_column :transactions, :guest_id, :string
  end
end
