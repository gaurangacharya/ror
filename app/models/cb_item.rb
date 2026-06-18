# == Schema Information
#
# Table name: cb_items
#
#  id             :integer          not null, primary key
#  item_id        :string(255)
#  name           :string(255)
#  description    :text(65535)
#  status         :string(255)
#  chargebee_data :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class CbItem < ApplicationRecord
  serialize :chargebee_data, JSON
end
