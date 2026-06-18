# == Schema Information
#
# Table name: subscriptions
#
#  id                     :integer          not null, primary key
#  chargebee_id           :string(255)
#  plan_id                :integer
#  plan_quantity          :integer          default(1)
#  person_id              :string(255)
#  status                 :string(255)
#  event_last_modified_at :datetime
#  chargebee_data         :text(65535)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_subscriptions_on_person_id  (person_id)
#  index_subscriptions_on_plan_id    (plan_id)
#

class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :plan
  has_one :payment_method, dependent: :destroy
  include ChargebeeRails::Subscription
  serialize :chargebee_data, JSON
end
