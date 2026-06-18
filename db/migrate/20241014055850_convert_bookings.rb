class ConvertBookings < ActiveRecord::Migration[5.2]
  def up
    change_column :bookings, :binary_mask, :decimal, precision: 40, scale: 0, default: 0
  end

  def down
    change_column :bookings, :binary_mask, :integer, default: 0
  end
end
