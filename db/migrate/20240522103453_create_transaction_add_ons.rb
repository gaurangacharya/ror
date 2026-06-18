class CreateTransactionAddOns < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_add_ons do |t|
      t.references :tx
      t.string :title
      t.integer :price_cents
      t.string :currency

      t.timestamps
    end
  end
end
