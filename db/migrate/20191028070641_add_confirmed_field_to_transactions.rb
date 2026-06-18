class AddConfirmedFieldToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :auto_confirm, :boolean, default: false rescue nil
  end
end
