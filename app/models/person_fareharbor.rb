# == Schema Information
#
# Table name: person_fareharbors
#
#  id                   :bigint           not null, primary key
#  person_id            :string(22)
#  fareharbor_shortname :string(255)
#  fareharbor_items     :integer
#  updated              :integer
#  failed               :integer
#  deleted              :integer
#  start_at             :datetime
#  end_at               :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_person_fareharbors_on_person_id  (person_id)
#

class PersonFareharbor < ApplicationRecord
  belongs_to :person

  scope :latest, ->{ order(created_at: :desc) }
end
