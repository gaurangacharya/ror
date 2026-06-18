# == Schema Information
#
# Table name: transaction_add_ons
#
#  id          :bigint           not null, primary key
#  tx_id       :bigint
#  title       :string(255)
#  price_cents :integer
#  currency    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_transaction_add_ons_on_tx_id  (tx_id)
#

class Transaction::AddOn < ApplicationRecord
  belongs_to :tx, class_name: 'Transaction', foreign_key: "tx_id"

  monetize :price_cents, allow_nil: true, with_model_currency: :currency
end
