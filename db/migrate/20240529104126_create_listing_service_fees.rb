class CreateListingServiceFees < ActiveRecord::Migration[5.2]
  def change
    create_table :listing_service_fees do |t|
      t.string :person_id, limit: 22, index: true
      t.string :title
      t.string :percent

      t.timestamps
    end
  end
end
