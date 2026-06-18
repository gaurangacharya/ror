# == Schema Information
#
# Table name: payment_methods
#
#  id                     :integer          not null, primary key
#  cb_customer_id         :string(255)
#  auto_collection        :boolean
#  payment_type           :string(255)
#  reference_id           :string(255)
#  card_last4             :string(255)
#  card_type              :string(255)
#  status                 :string(255)
#  event_last_modified_at :datetime
#  subscription_id        :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_payment_methods_on_subscription_id  (subscription_id)
#

require 'spec_helper'

RSpec.describe PaymentMethod, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
