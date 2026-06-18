class ListingsListingTaxes < ActiveRecord::Migration[5.2]
  def change
    create_join_table :listings, :listing_taxes do |t|
      t.index :listing_id
      t.index :listing_tax_id
    end
  end
end
