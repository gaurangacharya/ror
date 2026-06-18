class AddFieldsToSignupPlans < ActiveRecord::Migration[5.1]
  def change
    add_column :signup_plans, :signup_button_text, :string
    add_column :signup_plans, :create_account_button_text, :string
  end
end
