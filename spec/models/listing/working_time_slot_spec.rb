# == Schema Information
#
# Table name: listing_working_time_slots
#
#  id             :integer          not null, primary key
#  listing_id     :integer
#  week_day       :integer
#  from           :string(255)
#  till           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  start_time     :datetime
#  end_time       :datetime
#  calendar       :boolean          default(FALSE)
#  binary_mask    :integer          default(0)
#  booked_mask    :integer          default(0)
#  available_mask :integer          default(0)
#  max_hours      :integer          default(0)
#  per_day        :boolean          default(FALSE)
#
# Indexes
#
#  index_listing_and_time                          (listing_id,start_time,end_time)
#  index_listing_working_time_slots_on_listing_id  (listing_id)
#  index_working_time_slots_on_start_end_time      (calendar,start_time,end_time,listing_id)
#

require 'spec_helper'

RSpec.describe Listing::WorkingTimeSlot, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
