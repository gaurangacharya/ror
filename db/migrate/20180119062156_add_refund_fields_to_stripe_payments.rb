class AddRefundFieldsToStripePayments < ActiveRecord::Migration[5.1]
  def change
    add_column :stripe_payments, :is_refunded, :boolean, default: false
    add_column :stripe_payments, :refund_amount_cents, :integer
    add_column :stripe_payments, :refund_id, :string
  end
end
