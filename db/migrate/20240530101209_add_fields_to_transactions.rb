class AddFieldsToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :tax_percent, :string
    add_column :transactions, :tax_cents, :integer
    add_column :transactions, :service_fee_percent, :string
    add_column :transactions, :service_fee_cents, :integer
  end
end
