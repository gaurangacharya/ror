class ChangeMembershipStatusPeople < ActiveRecord::Migration[5.1]
  def change
    change_column :people, :membership_status, :integer, default: 0, null: false
  end
end
