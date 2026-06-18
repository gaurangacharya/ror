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

class Plan < ActiveRecord::Base
  has_many :subscriptions
  serialize :chargebee_data, JSON
end
