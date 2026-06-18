# == Schema Information
#
# Table name: tripadvisor_responses
#
#  id          :integer          not null, primary key
#  location_id :string(255)
#  body        :text(16777215)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class TripadvisorResponse < ApplicationRecord
  serialize :body, Hash

  def outdated?
    new_record? || updated_at < 1.day.ago
  end
end
