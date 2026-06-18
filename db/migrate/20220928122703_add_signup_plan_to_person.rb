class AddSignupPlanToPerson < ActiveRecord::Migration[5.1]
  def change
    add_reference :people, :signup_plan
  end
end
