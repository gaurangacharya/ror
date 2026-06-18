class AddPaypalRefundTransactionIdToPaypalPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :paypal_payments, :paypal_refund_transaction_id, :string
    add_column :paypal_payments, :refund_total_cents, :integer
    add_column :paypal_payments, :refund_fee_total_cents, :integer
  end
end
