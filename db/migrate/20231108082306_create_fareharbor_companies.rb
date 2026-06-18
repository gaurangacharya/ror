class CreateFareharborCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :fareharbor_companies do |t|
      t.references :person, type: :string, limit: 22
      t.boolean :active
      t.boolean :new_listings_open
      t.references :category
      t.string :name
      t.string :shortname
      t.string :currency
      t.datetime :affiliated_since
      t.text :summary
      t.text :about
      t.text :booking_notes
      t.text :faq
      t.text :intro
      t.string :address_street
      t.string :address_city
      t.string :address_province
      t.string :address_country
      t.string :address_postal_code
      t.string :billing_address_street
      t.string :billing_address_city
      t.string :billing_address_province
      t.string :billing_address_country
      t.string :billing_address_postal_code
      t.references :primary_location
      t.string :primary_location_heading, limit: 1024
      t.string :url, limit: 1024
      t.string :facebook_url, limit: 1024
      t.string :instagram_url, limit: 1024
      t.string :tripadvisor_url, limit: 1024
      t.string :twitter_url, limit: 1024
      t.string :yelp_url, limit: 1024
      t.string :youtube_url, limit: 1024
      t.string :pinterest_url, limit: 1024
      t.text :health_and_safety_policy
      t.json :open_hours

      t.timestamps
    end
    add_index :fareharbor_companies, :shortname
  end
end
