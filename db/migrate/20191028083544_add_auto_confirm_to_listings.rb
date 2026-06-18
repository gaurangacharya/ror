class AddAutoConfirmToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :auto_confirm, :boolean, default: true
  end
end
