class AddPersonWhiteLabelToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_reference :transactions, :person_white_label
  end
end
