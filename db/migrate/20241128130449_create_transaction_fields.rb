class CreateTransactionFields < ActiveRecord::Migration[5.2]
  def change
    create_table :transaction_fields do |t|
      t.references :transaction
      t.string :title
      t.string :type
      t.boolean :value_checkbox
      t.string :value_text
      t.datetime :value_date

      t.timestamps
    end
  end
end
