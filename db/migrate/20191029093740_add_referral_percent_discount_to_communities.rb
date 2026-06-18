class AddReferralPercentDiscountToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :referral_discount, :integer
  end
end
