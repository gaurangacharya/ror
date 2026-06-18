# == Schema Information
#
# Table name: fareharbor_companies
#
#  id                          :bigint           not null, primary key
#  person_id                   :string(22)
#  active                      :boolean
#  new_listings_open           :boolean
#  category_id                 :bigint
#  name                        :string(255)
#  shortname                   :string(255)
#  currency                    :string(255)
#  affiliated_since            :datetime
#  summary                     :text(65535)
#  about                       :text(65535)
#  booking_notes               :text(65535)
#  faq                         :text(65535)
#  intro                       :text(65535)
#  address_street              :string(255)
#  address_city                :string(255)
#  address_province            :string(255)
#  address_country             :string(255)
#  address_postal_code         :string(255)
#  billing_address_street      :string(255)
#  billing_address_city        :string(255)
#  billing_address_province    :string(255)
#  billing_address_country     :string(255)
#  billing_address_postal_code :string(255)
#  primary_location_id         :bigint
#  primary_location_heading    :string(1024)
#  url                         :string(1024)
#  facebook_url                :string(1024)
#  instagram_url               :string(1024)
#  tripadvisor_url             :string(1024)
#  twitter_url                 :string(1024)
#  yelp_url                    :string(1024)
#  youtube_url                 :string(1024)
#  pinterest_url               :string(1024)
#  health_and_safety_policy    :text(65535)
#  open_hours                  :json
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_fareharbor_companies_on_category_id          (category_id)
#  index_fareharbor_companies_on_person_id            (person_id)
#  index_fareharbor_companies_on_primary_location_id  (primary_location_id)
#  index_fareharbor_companies_on_shortname            (shortname)
#

class FareharborCompany < ApplicationRecord
  include RansackSearchable

  belongs_to :person
  belongs_to :category
  belongs_to :primary_location, class_name: 'Location', foreign_key: 'primary_location_id'

  scope :active, ->{ where(active: true) }
end
