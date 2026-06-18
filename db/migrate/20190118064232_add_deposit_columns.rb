class AddDepositColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :deposit_cents, :integer
    add_column :transactions, :deposit_cents, :integer
    add_column :stripe_payments, :is_deposit, :boolean, default: false
  end
end
