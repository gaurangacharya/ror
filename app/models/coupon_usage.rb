# == Schema Information
#
# Table name: coupon_usages
#
#  id         :integer          not null, primary key
#  coupon_id  :integer
#  value      :integer
#  person_id  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CouponUsage < ApplicationRecord
  belongs_to :coupon
  belongs_to :person
end
