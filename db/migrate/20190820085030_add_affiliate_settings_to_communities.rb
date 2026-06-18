class AddAffiliateSettingsToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :affiliate_percent, :float, default: 10.0
    add_column :communities, :membership_extend, :integer, default: 3
  end
end
