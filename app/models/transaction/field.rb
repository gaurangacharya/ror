# == Schema Information
#
# Table name: transaction_fields
#
#  id             :bigint           not null, primary key
#  transaction_id :bigint
#  title          :string(255)
#  type           :string(255)
#  value_checkbox :boolean
#  value_text     :string(255)
#  value_date     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_transaction_fields_on_transaction_id  (transaction_id)
#

class Transaction::Field < ApplicationRecord
  TYPES = [
    TYPE_CHECKBOX = 'Transaction::FieldCheckbox',
    TYPE_TEXT = 'Transaction::FieldText',
    TYPE_DATE = 'Transaction::FieldDate',
    TYPE_EMAIL = 'Transaction::FieldEmail',
  ]
  belongs_to :tx, class_name: 'Transaction', foreign_key: "transaction_id"
end
