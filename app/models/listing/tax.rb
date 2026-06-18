# == Schema Information
#
# Table name: listing_taxes
#
#  id         :bigint           not null, primary key
#  person_id  :string(22)
#  title      :string(255)
#  percent    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_listing_taxes_on_person_id  (person_id)
#

class Listing::Tax < ApplicationRecord
  belongs_to :person
  has_and_belongs_to_many :listings, foreign_key: :listing_tax_id

  scope :for_person, ->(person) { where(person:person) }
end
