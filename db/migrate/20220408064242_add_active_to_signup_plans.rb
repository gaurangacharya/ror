class AddActiveToSignupPlans < ActiveRecord::Migration[5.1]
  def change
    add_column :signup_plans, :active, :boolean, default: false
    add_column :signup_plans, :position, :integer, default: 0
  end
end
