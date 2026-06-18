class AddReferralIdToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :referral_id, :string
  end
end
