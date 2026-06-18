class ChangeReferralDiscountToInteger < ActiveRecord::Migration[5.1]
  def change
    change_column :communities, :referral_discount, :integer, default: 0
  end
end
