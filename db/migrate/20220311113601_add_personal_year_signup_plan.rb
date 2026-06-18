class AddPersonalYearSignupPlan < ActiveRecord::Migration[5.1]
  def up
    SignupPlan.where(
      code: 'personal_year',
      title: 'Premium Membership',
    ).first_or_create
  end
  def down
    SignupPlan.find_by(code: 'personal_year')&.destroy
  end
end
