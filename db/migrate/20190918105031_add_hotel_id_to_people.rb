class AddHotelIdToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :hotel_id, :string
  end
end
