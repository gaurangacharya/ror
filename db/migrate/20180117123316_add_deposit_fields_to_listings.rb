class AddDepositFieldsToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :deposit_cents, :integer, default: 0
    add_column :transactions, :deposit_cents, :integer, default: 0
    add_column :stripe_payments, :is_deposit, :boolean, default: false
  end
end
