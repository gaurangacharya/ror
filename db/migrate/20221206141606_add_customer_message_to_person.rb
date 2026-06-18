class AddCustomerMessageToPerson < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :customer_message_under_book, :string
  end
end
