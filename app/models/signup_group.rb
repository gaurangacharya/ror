# == Schema Information
#
# Table name: signup_groups
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  position   :integer          default(0)
#  active     :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  is_default :boolean          default(FALSE)
#

class SignupGroup < ApplicationRecord
  has_many :signup_plans, -> { active.sorted }

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order('position ASC') }
  scope :default, -> { where(is_default: true) }

  after_save :remove_default_from_other_entries

  private

  def remove_default_from_other_entries
    if is_default
      self.class.where.not(id: id).update_all(is_default: false)
    end
  end

  class << self
    def get_default
      active.default.first || active.first
    end
  end
end
