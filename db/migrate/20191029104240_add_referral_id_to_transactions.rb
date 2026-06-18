class AddReferralIdToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :referral_id, :string
    add_column :transactions, :referral_discount, :integer
  end
end
