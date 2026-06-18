class AddStripeCheckoutIdToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :signup_charge_id, :string
  end
end
