# == Schema Information
#
# Table name: plans
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  plan_id        :string(255)
#  status         :string(255)
#  chargebee_data :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

RSpec.describe Plan, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
