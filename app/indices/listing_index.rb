if APP_CONFIG.use_thinking_sphinx_indexing.to_s.casecmp("true") == 0
  ThinkingSphinx::Index.define :listing, :with => :real_time do

    #Thinking Sphinx will automatically add the SQL command SET NAMES utf8 as
    # part of the indexing process if the database connection settings have
    # encoding set to utf8. This is default in Rails but with Heroku, we need to
    # be explicit.
    set_property :utf8? => true

    # limit to open listings
    scope { Listing.open_and_valid_now }

    # fields
    indexes title
    indexes description
    indexes custom_text_fields
    indexes origin_loc.google_address
    indexes author_name

    # attributes
    has id, :as => :listing_id, type: :integer # id didn't work without :as aliasing
    has open, type: :integer
    has deleted, type: :integer
    has price_cents, type: :integer
    has created_at, updated_at, type: :timestamp
    has sort_date, type: :timestamp
    has category_id, type: :integer
    has listing_shape_id, type: :integer
    has community_id, type: :integer
    has custom_dropdown_field_options, type: :integer, multi: true
    has custom_checkbox_field_options, type: :integer, multi: true
    has origin_loc.latitude,  as: :latitude_deg, type: :float
    has origin_loc.longitude, as: :longitude_deg, type: :float
    has latitude_rad, as: :latitude, type: :float
    has longitude_rad, as: :longitude, type: :float
    has author.rating_count, as: :rating_count, type: :float
    has author.rating_average, as: :rating_average, type: :float
    has author.is_confirmed, :as => :author_confirmed, type: :integer
    has author.is_vendor, :as => :author_vendor, type: :integer
    has author.sort_priority, :as => :author_sort_priority, type: :integer
    has author.is_affiliate, :as => :author_affiliate, type: :integer
    has affiliate_pricing, type: :integer
    has author_id, type: :string
    has call_for_price, type: :integer
    has hide_price, type: :integer
    has instant_booking, type: :integer
    has guest_only, type: :integer
    has admin_rating, type: :integer
    has show_for_people_count, type: :integer
    has ajusted_listing_show_for_person_ids, type: :integer, multi: true

    set_property :field_weights => {
      :title       => 10,
      :category    => 8,
      :description => 3,
      :author_name => 20
    }

  end
end
