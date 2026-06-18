class CreateListingAddOns < ActiveRecord::Migration[5.2]
  def change
    create_table :listing_add_ons do |t|
      t.references :listing
      t.string :title
      t.integer :price_cents
      t.string :currency

      t.timestamps
    end
  end
end
