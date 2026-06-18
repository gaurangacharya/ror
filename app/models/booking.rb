# == Schema Information
#
# Table name: bookings
#
#  id             :integer          not null, primary key
#  transaction_id :integer
#  start_on       :date
#  end_on         :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  start_time     :datetime
#  end_time       :datetime
#  per_hour       :boolean          default(FALSE)
#  binary_mask    :decimal(40, )    default(0)
#  listing_id     :integer
#
# Indexes
#
#  index_bookings_on_end_time                   (end_time)
#  index_bookings_on_listing_id_and_start_time  (listing_id,start_time)
#  index_bookings_on_per_hour                   (per_hour)
#  index_bookings_on_start_end_time             (start_time,end_time)
#  index_bookings_on_start_time                 (start_time)
#  index_bookings_on_transaction_id             (transaction_id)
#

class Booking < ApplicationRecord
  include AvailabilityMask

  belongs_to :tx, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :listing

  attr_accessor :skip_validation

  #validate :per_day_availability, unless: :skip_validation
  validate :per_hour_availability, unless: :skip_validation


  scope :in_period, ->(start_time, end_time) { where(['start_time >= ? AND end_time <= ?', start_time, end_time]) }

  scope :hourly_basis, -> { where(per_hour: true) }
  scope :daily_basis, -> { where(per_hour: false) }
  scope :covers_another_booking_per_hour, ->(booking) do
    exclude_self(booking)
    .joins(:tx).per_hour_blocked
    .where(['start_time < ? AND end_time > ?', booking.end_time, booking.start_time])
  end
  scope :availability_blocking, -> { joins(:tx).merge(Transaction.availability_blocking) }
  scope :per_hour_blocked, -> { hourly_basis.availability_blocking }
  scope :per_day_blocked, -> { daily_basis.availability_blocking }

  # NOTE: this is MySQL specific optimization to allow efficient use of indexes on start_time, end_time with range query, therefore two extra conditions
  scope :in_period_using_index, ->(start_time, end_time) do
    where(['start_time >= ? AND start_time <= ? AND end_time >= ? AND end_time <= ?', start_time, end_time, start_time, end_time])
  end
  scope :overlapping_with_period, ->(start_time, end_time) { where(['end_time >= ? AND start_time <= ?', start_time, end_time]) }
  scope :overlapping_with_date_period, ->(start_time, end_time) { where(['end_on > ? AND start_on <= ?', start_time, end_time]) }
  scope :blocked_in_interval, ->(start_date, end_date) { per_hour_blocked.overlapping_with_period(start_date, end_date) }
  scope :for_buyer, ->(person_id) { where('transactions.starter_id = ?', person_id) }
  scope :by_date, ->(start_time) { where('DATE(start_time) = DATE(?)', start_time) }
  scope :covers_another_booking_per_day, ->(booking) do
    exclude_self(booking)
    .joins(:tx).per_day_blocked
    .where(['start_on < ? AND end_on > ?', booking.end_on, booking.start_on])
  end
  scope :exclude_self, ->(booking) do
    booking.persisted? ? where.not(id: booking.id) : self
  end
  
  def week_day
    Listing::WorkingTimeSlot.week_days.keys[start_time.wday].to_sym
  end

  def self.columns
    super.reject { |c| c.name == "end_on_exclusive" }
  end

  def duration
    if per_hour
      DateUtils.duration_in_hours(start_time, end_time)
    else
      DateUtils.duration(start_on, end_on)
    end
  end

  before_validation :set_binary_mask
  def set_binary_mask
    if start_time.present? && end_time.present?
      self.binary_mask = calculate_binary_mask(start_time, end_time)
    end
  end

  after_save :update_booked_masks_in_slots
  def update_booked_masks_in_slots
    tx.listing.update_booked_slots(self.start_time) if per_hour?
  end

  def more_than_week?
    !per_hour && duration >= 7
  end

  def start_date_time
    t = per_hour ? start_time : start_on.to_time
    listing.auto_time_zone.local(t.year, t.month, t.day, t.hour, t.min)
  end

  def end_date_time
    t = per_hour ? end_time : end_on.to_time
    listing.auto_time_zone.local(t.year, t.month, t.day, t.hour, t.min)
  end

  def in_future?
    start_date_time > Time.zone.now
  end

  def in_past?
    end_date_time <= Time.zone.now
  end

  def direct_validation
    per_day_availability
    per_hour_availability
  end

  private

  def per_day_availability
    return true if per_hour

    self.class.uncached do
      if tx.listing.bookings.covers_another_booking_per_day(self).any? ||
         tx.listing.blocked_dates.in_period_end_exclusive(self.start_on, self.end_on).any?
        errors.add(:start_on, :invalid)
        errors.add(:end_on, :invalid)
      end
    end
  end

  def per_hour_availability
    return true unless per_hour

    self.class.uncached do
      unless tx.listing.working_hours_covers_booking?(self) && can_book_per_hour?
        errors.add(:start_time, :invalid)
        errors.add(:end_time, :invalid)
      end
    end
  end

  def can_book_per_hour?
    bookings_sope = listing.bookings_per_hour.by_date(self.start_time)
    bookings_sope = bookings_sope.where('bookings.id <> ?', self.id) if persisted?
    booked_mask = Listing::WorkingTimeSlot.booked_mask_by_date(bookings_sope, listing.capacity, tx.listing_quantity)
    binary_mask == (binary_mask & ~booked_mask)
  end
end
