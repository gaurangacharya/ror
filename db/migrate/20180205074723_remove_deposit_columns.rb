class RemoveDepositColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :listings, :deposit_cents, :integer
    remove_column :transactions, :deposit_cents, :integer
    remove_column :stripe_payments, :is_deposit, :boolean, default: false
  end
end
