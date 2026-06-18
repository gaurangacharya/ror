class AddPremiumToCommunities < ActiveRecord::Migration[5.1]
  def change
    add_column :communities, :premium_for_everyone, :boolean
  end
end
