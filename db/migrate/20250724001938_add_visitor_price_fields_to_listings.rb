class AddVisitorPriceFieldsToListings < ActiveRecord::Migration[6.1]
  def change
    add_column :listings, :visitor_price_cents, :integer
    add_column :listings, :visitor_price_currency, :string, limit: 8
    
    # Set default visitor price to be the same as current price for existing listings
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE listings 
          SET visitor_price_cents = price_cents, 
              visitor_price_currency = currency 
          WHERE price_cents IS NOT NULL
        SQL
      end
    end
  end
end
