class ListingsListingServiceFees < ActiveRecord::Migration[5.2]
  def change
    create_join_table :listings, :listing_service_fees do |t|
      t.index :listing_id
      t.index :listing_service_fee_id
    end
  end
end
