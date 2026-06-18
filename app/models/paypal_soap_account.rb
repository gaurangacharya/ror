# == Schema Information
#
# Table name: paypal_soap_accounts
#
#  id         :bigint           not null, primary key
#  person_id  :string(22)
#  login      :string(255)
#  password   :string(255)
#  signature  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_paypal_soap_accounts_on_person_id  (person_id)
#

class PaypalSoapAccount < ApplicationRecord
  belongs_to :person

  def filled?
    login.present? && password.present? && signature.present?
  end
end
