class AddFareharborToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :fareharbor_company_id, :string
    add_index :listings, :fareharbor_company_id
    add_column :listings, :fareharbor_item_id, :string
    add_index :listings, :fareharbor_item_id
  end
end
