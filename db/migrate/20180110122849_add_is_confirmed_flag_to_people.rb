class AddIsConfirmedFlagToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :is_confirmed, :integer, default: 0
  end
end
