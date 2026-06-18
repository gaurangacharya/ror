# == Schema Information
#
# Table name: listing_show_for_people
#
#  id         :integer          not null, primary key
#  listing_id :integer
#  person_id  :string(22)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_listing_show_for_people_on_listing_id  (listing_id)
#  index_listing_show_for_people_on_person_id   (person_id)
#

class ListingShowForPerson < ApplicationRecord
  belongs_to :listing
  belongs_to :person

  scope :by_username, -> (username) { joins(:person).where(people: { username: username }) }
end
