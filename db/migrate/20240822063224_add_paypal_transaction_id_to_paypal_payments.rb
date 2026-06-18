class AddPaypalTransactionIdToPaypalPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :paypal_payments, :paypal_transaction_id, :string
  end
end
