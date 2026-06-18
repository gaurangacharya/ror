# == Schema Information
#
# Table name: locations
#
#  id             :integer          not null, primary key
#  latitude       :float(24)
#  longitude      :float(24)
#  address        :string(255)
#  google_address :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  listing_id     :integer
#  person_id      :string(255)
#  location_type  :string(255)
#  community_id   :integer
#  referral_id    :string(255)
#
# Indexes
#
#  index_locations_on_community_id  (community_id)
#  index_locations_on_listing_id    (listing_id)
#  index_locations_on_person_id     (person_id)
#

class Location < ApplicationRecord

  belongs_to :person
  belongs_to :listing
  belongs_to :community
  belongs_to :referral, class_name: 'Person', foreign_key: :referral_id

  def search_and_fill_latlng(address=nil, locale=APP_CONFIG.default_locale)
    okresponse = false
    # Use server-side key if available (should have IP restrictions), otherwise fall back to regular key
    api_key = APP_CONFIG.google_maps_server_key.presence || APP_CONFIG.google_maps_key
    geocoder = "https://maps.googleapis.com/maps/api/geocode/json?key=#{api_key}&address="

    if address == nil
      address = self.address
    end

    if address != nil && address != ""
      url = URI.escape(geocoder+address)
      resp = RestClient.get(url)
      result = JSON.parse(resp.body)
      logger.info("GEOCODE:#{result.inspect}")

      if result["status"] == "OK"
        self.address = address unless self.address.present?
        self.google_address = result["results"][0]["formatted_address"] if result["results"][0]["formatted_address"]
        self.latitude = result["results"][0]["geometry"]["location"]["lat"]
        self.longitude = result["results"][0]["geometry"]["location"]["lng"]
        okresponse = true
      else
        # Log geocoding errors for debugging
        logger.warn("Geocoding failed for address: #{address}, status: #{result['status']}, error: #{result['error_message']}")
      end
    end
    okresponse
  end

  def has_coords?
    latitude.present? && longitude.present?
  end

  def bounding_box_params
    return "" unless has_coords?
    box = [
      add_north(latitude, longitude, -DELTA),
      add_west(latitude, longitude, -DELTA),
      add_north(latitude, longitude, DELTA),
      add_west(latitude, longitude, DELTA),
    ].map{|x| sprintf("%2.5f", x)}
    return "boundingbox=#{box.join('%2C')}&distance_max=100&lc=#{latitude}%2c#{longitude}"
  end

  DELTA = 100

  EARTH_RADIUS = 6335000 / 1609.3

  def add_north(latitude, longitude, miles)
    x = miles * 180 / (Math::PI * EARTH_RADIUS)
    latitude + x
  end

  def add_west(latitude, longitude, miles)
    x = miles * 180 / (Math::PI * EARTH_RADIUS * Math.cos(to_radians(latitude)))
    longitude + x
  end

  def to_radians(degrees)
    degrees.to_f * Math::PI / 180
  end

end
