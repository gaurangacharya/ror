# == Schema Information
#
# Table name: signup_plans
#
#  id                         :integer          not null, primary key
#  code                       :string(255)
#  title                      :string(255)
#  subtitle                   :string(255)
#  price_title                :string(255)
#  plan_body                  :text(65535)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  active                     :boolean          default(FALSE)
#  position                   :integer          default(0)
#  signup_group_id            :integer
#  signup_button_text         :string(255)
#  create_account_button_text :string(255)
#
# Indexes
#
#  index_signup_plans_on_signup_group_id  (signup_group_id)
#

class SignupPlan < ApplicationRecord
  HEAD = 'head'
  FREE = 'free'

  # hardcoded "Personal-Premium"
  PERSONAL_PREMIUM_ID = 3

  belongs_to :signup_group

  scope :active, -> { where(active: true) }
  scope :plans, -> do
    active.sorted.where.not(code: [HEAD])
  end
  scope :sorted, -> { order('position ASC') }

  def free?
    code == FREE
  end

  class << self
    def available_codes
      codes = [[HEAD, HEAD], [FREE, FREE]]
      codes += CbItem.all.map{|item| ["#{item.name} (ChargeBee)", item.item_id]}
    end
  end
end
