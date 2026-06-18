# == Schema Information
#
# Table name: transactions
#
#  id                                :integer          not null, primary key
#  starter_id                        :string(255)      not null
#  starter_uuid                      :binary(16)       not null
#  listing_id                        :integer          not null
#  listing_uuid                      :binary(16)       not null
#  conversation_id                   :integer
#  automatic_confirmation_after_days :integer          not null
#  community_id                      :integer          not null
#  community_uuid                    :binary(16)       not null
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  starter_skipped_feedback          :boolean          default(FALSE)
#  author_skipped_feedback           :boolean          default(FALSE)
#  last_transition_at                :datetime
#  current_state                     :string(255)
#  commission_from_seller            :integer
#  minimum_commission_cents          :integer          default(0)
#  minimum_commission_currency       :string(255)
#  payment_gateway                   :string(255)      default("none"), not null
#  listing_quantity                  :integer          default(1)
#  listing_author_id                 :string(255)      not null
#  listing_author_uuid               :binary(16)       not null
#  listing_title                     :string(255)
#  unit_type                         :string(32)
#  unit_price_cents                  :integer
#  unit_price_currency               :string(8)
#  unit_tr_key                       :string(64)
#  unit_selector_tr_key              :string(64)
#  payment_process                   :string(31)       default("none")
#  delivery_method                   :string(31)       default("none")
#  shipping_price_cents              :integer
#  availability                      :string(32)       default("none")
#  booking_uuid                      :binary(16)
#  deleted                           :boolean          default(FALSE)
#  deposit_cents                     :integer
#  guest_id                          :string(255)
#  auto_confirm                      :boolean          default(FALSE)
#  referral_id                       :string(255)
#  referral_discount                 :integer
#  person_white_label_id             :bigint
#  tax_percent                       :string(255)
#  tax_cents                         :integer
#  service_fee_percent               :string(255)
#  service_fee_cents                 :integer
#  listing_price_cents               :integer
#
# Indexes
#
#  index_transactions_on_community_id           (community_id)
#  index_transactions_on_conversation_id        (conversation_id)
#  index_transactions_on_deleted                (deleted)
#  index_transactions_on_last_transition_at     (last_transition_at)
#  index_transactions_on_listing_author_id      (listing_author_id)
#  index_transactions_on_listing_id             (listing_id)
#  index_transactions_on_person_white_label_id  (person_white_label_id)
#  index_transactions_on_starter_id             (starter_id)
#  transactions_on_cid_and_deleted              (community_id,deleted)
#

class Transaction < ApplicationRecord
  attr_accessor :contract_agreed

  belongs_to :community
  belongs_to :listing
  has_many :transaction_transitions, dependent: :destroy, foreign_key: :transaction_id
  has_one :booking, :dependent => :destroy
  has_one :shipping_address, dependent: :destroy
  belongs_to :starter, :class_name => "Person", :foreign_key => "starter_id"
  belongs_to :conversation
  has_many :testimonials
  belongs_to :guest, :class_name => 'Person', :foreign_key => "guest_id"
  has_many :documents
  belongs_to :person_white_label
  has_one :paypal_payment, :dependent => :destroy
  has_many :add_ons, dependent: :destroy, foreign_key: :tx_id
  has_many :fields, dependent: :destroy

  delegate :author, to: :listing
  delegate :title, to: :listing, prefix: true

  accepts_nested_attributes_for :booking
  accepts_nested_attributes_for :add_ons
  accepts_nested_attributes_for :fields

  validates_presence_of :payment_gateway

  monetize :minimum_commission_cents, with_model_currency: :minimum_commission_currency
  monetize :unit_price_cents, with_model_currency: :unit_price_currency
  monetize :shipping_price_cents, allow_nil: true, with_model_currency: :unit_price_currency
  monetize :deposit_cents, allow_nil: true, with_model_currency: :unit_price_currency
  monetize :tax_cents, allow_nil: true, with_model_currency: :unit_price_currency
  monetize :service_fee_cents, allow_nil: true, with_model_currency: :unit_price_currency
  monetize :listing_price_cents, allow_nil: true, with_model_currency: :unit_price_currency

  scope :for_person, -> (person){
    joins(:listing)
    .where("listings.author_id = ? OR starter_id = ?", person.id, person.id)
  }
  scope :availability_blocking, -> do
    where(current_state: ['preauthorized', 'paid', 'confirmed', 'canceled', 'free'])
  end
  scope :by_paypal_token, -> (token) do
    joins(:paypal_payment).merge(PaypalPayment.by_token(token))
  end
  scope :not_deleted, -> { where(deleted: false) }
  scope :ignore_initiated, -> { where.not(current_state: 'initiated') }

  before_create :set_tax_and_service_fee

  def booking_uuid_object
    if self[:booking_uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:booking_uuid])
    end
  end

  def booking_uuid_object=(uuid)
    self.booking_uuid = UUIDUtils.raw(uuid)
  end

  def community_uuid_object
    if self[:community_uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:community_uuid])
    end
  end

  def starter_uuid_object
    if self[:starter_uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:starter_uuid])
    end
  end

  def listing_author_uuid_object
    if self[:listing_author_uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:listing_author_uuid])
    end
  end

  def status
    current_state
  end

  def has_feedback_from?(person)
    if author == person
      testimonial_from_author.present?
    else
      testimonial_from_starter.present?
    end
  end

  def feedback_skipped_by?(person)
    if author == person
      author_skipped_feedback?
    else
      starter_skipped_feedback?
    end
  end

  def testimonial_from_author
    testimonials.find { |testimonial| testimonial.author_id == author.id }
  end

  def testimonial_from_starter
    testimonials.find { |testimonial| testimonial.author_id == starter.id }
  end

  # TODO This assumes that author is seller (which is true for all offers, sell, give, rent, etc.)
  # Change it so that it looks for TransactionProcess.author_is_seller
  def seller
    author
  end

  # TODO This assumes that author is seller (which is true for all offers, sell, give, rent, etc.)
  # Change it so that it looks for TransactionProcess.author_is_seller
  def buyer
    starter
  end

  def participations
    [author, starter]
  end

  def payer
    starter
  end
  
  after_save :update_booked_masks_in_slots
  def update_booked_masks_in_slots
    listing.update_booked_slots(booking.start_time) if booking && booking.per_hour?
  end

  def payment_receiver
    author
  end

  # Return true if the transaction is in a state that it can be confirmed
  def can_be_confirmed?
    # TODO This is a lazy fix. Remove this method, and make the caller to use the service directly
    # Models should not know anything about services
    MarketplaceService::Transaction::Query.can_transition_to?(self.id, :confirmed)
  end

  # Return true if the transaction is in a state that it can be canceled
  def can_be_canceled?
    # TODO This is a lazy fix. Remove this method, and make the caller to use the service directly
    # Models should not know anything about services
    MarketplaceService::Transaction::Query.can_transition_to?(self.id, :canceled)
  end

  def with_type(&block)
    block.call(:listing_conversation)
  end

  def latest_activity
    (transaction_transitions + conversation.messages).max
  end

  # Give person (starter or listing author) and get back the other
  #
  # Note: I'm not sure whether we want to have this method or not but at least it makes refactoring easier.
  def other_party(person)
    person == starter ? listing.author : starter
  end

  def unit_type
    Maybe(read_attribute(:unit_type)).to_sym.or_else(nil)
  end

  has_one :deposit_payment, ->{ where(is_deposit: true) }, class_name: 'StripePayment'
  has_one :stripe_payment, ->{ where(is_deposit: false) }, class_name: 'StripePayment'

  def was_paid?
    stripe_payment.present? && (stripe_payment.status == 'paid' || stripe_payment.status == 'refunded')
  end

  def can_refund?
    deposit_payment.present? && deposit_payment.pending?
  end

  def refunded_amount
    deposit_payment.present? ? deposit_payment.refund_amount : nil
  end

  def deposit_status
    return "no_deposit"    if deposit.nil? || deposit <= 0
    return "no_booking"    if booking.nil?
    return "long_booking"  if booking && booking.more_than_week?
    return "scheduled"     if booking.in_future? && !deposit_payment
    return "cleared"       if deposit_payment && deposit_payment.cleared?
    return "partial_refund" if deposit_payment && deposit_payment.partial_refund?
    return "refunded"      if deposit_payment && deposit_payment.refunded?
    return "preauthorized" if deposit_payment && deposit_payment.pending?
    return "unknown"
  end

  def ignore_deposit?
    %w(no_deposit long_booking no_booking).include?(deposit_status)
  end

  def can_preauth_deposit?
    was_paid? && can_cancel_and_refund? && deposit_status == "scheduled" && (booking.start_date_time - 1.day) <= Time.zone.now
  end

  def can_cancel_and_refund?
    (current_state == 'paid' || current_state == 'confirmed' || current_state == 'canceled') && (stripe_payment&.status == 'paid' || paypal_payment&.completed?)
  end

  def user_by_ref_id
    return nil unless referral_id.present?
    person = Person.where(referral_id: referral_id, is_affiliate: true, community_id: community_id).first
    person&.id
  end

  def total_cents
    result = unit_price_cents * listing_quantity

    if shipping_price_cents.is_a?(Integer)
      result += shipping_price_cents
    end

    if tax_cents.is_a?(Integer)
      result += tax_cents
    end

    if service_fee_cents.is_a?(Integer)
      result += service_fee_cents
    end

    result
  end

  def total
    ::Money.new(total_cents, unit_price_currency)
  end

  def mark_as_seen_by_current(person_id)
    self.conversation
      .participations
      .where("person_id = '#{person_id}'")
      .update_all(is_read: true)
  end

  private

  def set_tax_and_service_fee
    subtotal = unit_price_cents * listing_quantity
    self.tax_cents = tax_percent.present? ? (subtotal * tax_percent.to_f / 100).floor(2) : nil
    self.service_fee_cents = service_fee_percent.present? ? (subtotal * service_fee_percent.to_f / 100).floor(2) : nil
  end
end
