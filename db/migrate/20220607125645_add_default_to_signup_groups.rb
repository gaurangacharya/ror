class AddDefaultToSignupGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :signup_groups, :is_default, :boolean, default: false
  end
end
