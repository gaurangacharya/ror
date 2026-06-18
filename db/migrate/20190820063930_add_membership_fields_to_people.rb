class AddMembershipFieldsToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :membership_status, :boolean, default: false
    add_column :people, :membership_expires_at, :date
    add_column :people, :referral_id, :string
  end
end
