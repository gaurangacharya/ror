# == Schema Information
#
# Table name: fareharbor_failures
#
#  id                   :bigint           not null, primary key
#  fareharbor_shortname :string(255)
#  fareharbor_item      :string(255)
#  exception            :text(65535)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  backtrace            :text(65535)
#

class FareharborFailure < ApplicationRecord
end
