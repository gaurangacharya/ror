class AddGuestFlagToPeople < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :guest, :boolean, default: false
  end
end
