class AddFieldsToPaypalPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :paypal_payments, :correlation_id, :string
    add_column :paypal_payments, :token, :string
  end
end
