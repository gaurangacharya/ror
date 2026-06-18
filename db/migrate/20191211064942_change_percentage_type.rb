class ChangePercentageType < ActiveRecord::Migration[5.1]
  def change
    change_column :communities, :referral_discount, :float, default: 0
    change_column :communities, :hotel_percent_guest, :float, default: 5
    change_column :communities, :platform_percent_guest, :float, default: 10
  end
end
