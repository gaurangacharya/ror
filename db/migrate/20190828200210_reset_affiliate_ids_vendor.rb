class ResetAffiliateIdsVendor < ActiveRecord::Migration[5.1]
  def change
    Person.where(is_vendor: true).update_all(referral_id: nil)
  end
end
