# == Schema Information
#
# Table name: coupons
#
#  id           :integer          not null, primary key
#  community_id :integer
#  value        :integer
#  code         :string(255)
#  is_active    :boolean
#  valid_until  :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Coupon < ApplicationRecord
  belongs_to :community
  has_many :coupon_usages

  NAME_CHARSET = %w{ 2 3 4 6 7 9 A C D E F H J K L M N P R T V W X Y Z}

  def self.generate_code
    (0...10).map{ NAME_CHARSET.to_a[rand(NAME_CHARSET.size)] }.join
  end

  def expired?
    valid_until && valid_until < Time.zone.now
  end

  def can_be_used?
    !expired?
  end

  def self.can_use?(community_id, code)
    coupon = Coupon.where(community_id: community_id, code: code.to_s.strip).first
    [coupon, coupon&.can_be_used?]
  end
end
