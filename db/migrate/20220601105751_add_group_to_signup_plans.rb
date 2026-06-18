class AddGroupToSignupPlans < ActiveRecord::Migration[5.1]
  def change
    add_reference :signup_plans, :signup_group
  end
end
