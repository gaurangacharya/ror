class AddReferralLocationToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :referral_address, :string
  end
end
