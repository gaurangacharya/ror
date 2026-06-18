# == Schema Information
#
# Table name: paypal_payments
#
#  id                           :integer          not null, primary key
#  community_id                 :integer          not null
#  transaction_id               :integer          not null
#  payer_id                     :string(64)       not null
#  receiver_id                  :string(64)       not null
#  merchant_id                  :string(255)      not null
#  order_id                     :string(64)
#  order_date                   :datetime
#  currency                     :string(8)        not null
#  order_total_cents            :integer
#  authorization_id             :string(64)
#  authorization_date           :datetime
#  authorization_expires_date   :datetime
#  authorization_total_cents    :integer
#  payment_id                   :string(64)
#  payment_date                 :datetime
#  payment_total_cents          :integer
#  fee_total_cents              :integer
#  payment_status               :string(64)       not null
#  pending_reason               :string(64)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  commission_payment_id        :string(64)
#  commission_payment_date      :datetime
#  commission_status            :string(64)       default("not_charged"), not null
#  commission_pending_reason    :string(64)
#  commission_total_cents       :integer
#  commission_fee_total_cents   :integer
#  correlation_id               :string(255)
#  token                        :string(255)
#  paypal_transaction_id        :string(255)
#  paypal_refund_transaction_id :string(255)
#  refund_total_cents           :integer
#  refund_fee_total_cents       :integer
#
# Indexes
#
#  index_paypal_payments_on_authorization_id  (authorization_id) UNIQUE
#  index_paypal_payments_on_community_id      (community_id)
#  index_paypal_payments_on_order_id          (order_id) UNIQUE
#  index_paypal_payments_on_transaction_id    (transaction_id) UNIQUE
#

class PaypalPayment < ApplicationRecord
  belongs_to :tx, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :payer, class_name: "Person", foreign_key: "payer_id"
  belongs_to :receiver, class_name: "Person", foreign_key: "receiver_id"

  scope :by_token, -> (token) do
    where(token: token)
  end

  validates_presence_of(
    :community_id,
    :transaction_id,
    :payer_id,
    :receiver_id,
    :currency,
    :payment_status,
    :commission_status)

  monetize :order_total_cents,          with_model_currency: :currency, allow_nil: true
  monetize :authorization_total_cents,  with_model_currency: :currency, allow_nil: true
  monetize :payment_total_cents,        with_model_currency: :currency, allow_nil: true
  monetize :fee_total_cents,            with_model_currency: :currency, allow_nil: true
  monetize :commission_total_cents,     with_model_currency: :currency, allow_nil: true
  monetize :commission_fee_total_cents, with_model_currency: :currency, allow_nil: true
  monetize :refund_total_cents,         with_model_currency: :currency, allow_nil: true
  monetize :refund_fee_total_cents,     with_model_currency: :currency, allow_nil: true

  # this is arranged with stripe payment
  alias_attribute :refund_amount, :refund_total
  alias_attribute :sum, :payment_total
  alias_attribute :status, :payment_status

  def completed?
    payment_status == 'completed' && paypal_transaction_id.present?
  end
  alias paid? completed?

  def refunded?
    payment_status == 'refunded'
  end

  def increment_commission_retry_count
    update_column(:commission_retry_count, commission_retry_count + 1)
  end

  def retry_charge_commision?
    commission_retry_count < MAX_CHARGE_COMMISSION_ATTEMPTS
  end

  def charge_commision_failed
    update_column(:commission_status, :failed)
  end
end
