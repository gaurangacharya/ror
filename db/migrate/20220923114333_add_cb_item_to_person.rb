class AddCbItemToPerson < ActiveRecord::Migration[5.1]
  def change
    add_reference :people, :cb_item
  end
end
