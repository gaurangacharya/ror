class AddListingPriceToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :listing_price_cents, :integer
  end
end
