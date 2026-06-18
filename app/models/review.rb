# == Schema Information
#
# Table name: reviews
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  content      :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  community_id :integer
#  author       :string(255)
#
# Indexes
#
#  index_reviews_on_community_id  (community_id)
#

class Review < ApplicationRecord
  belongs_to :community
end
