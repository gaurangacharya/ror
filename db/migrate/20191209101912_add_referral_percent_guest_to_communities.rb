class AddReferralPercentGuestToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :platform_percent_guest, :integer, default: 10
  end
end
