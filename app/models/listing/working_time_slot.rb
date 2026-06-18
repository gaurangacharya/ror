# == Schema Information
#
# Table name: listing_working_time_slots
#
#  id             :bigint           not null, primary key
#  listing_id     :integer
#  week_day       :integer
#  from           :string(255)
#  till           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  start_time     :datetime
#  end_time       :datetime
#  calendar       :boolean          default(FALSE)
#  binary_mask    :decimal(40, )    default(0)
#  booked_mask    :decimal(40, )    default(0)
#  available_mask :decimal(40, )    default(0)
#  max_capacity   :integer          default(0)
#  per_day        :boolean          default(FALSE)
#
# Indexes
#
#  index_listing_and_time                          (listing_id,start_time,end_time)
#  index_listing_working_time_slots_on_listing_id  (listing_id)
#  index_working_time_slots_on_start_end_time      (calendar,start_time,end_time,listing_id)
#

class Listing::WorkingTimeSlot < ApplicationRecord
  include AvailabilityMask
  include AvailabilityMaskManagment

  belongs_to :listing

  enum week_day: {sun: 0, mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6}

  scope :by_week_day, ->(day) { where(week_day: day) }
  scope :ordered, -> { order('listing_working_time_slots.start_time') }
  scope :calendar, -> { where(calendar: true) }
  scope :per_day, -> { where(per_day: true) }

  scope :interval, ->(start_date, end_date){ calendar.where("end_time >= ? AND start_time <= ?", start_date, end_date) }
  # NOTE: this is MySQL specific optimization to allow efficient use of indexes on start_time, end_time with range query, therefore two extra conditions
  scope :in_period_using_index, ->(start_time, end_time) do
    where(['start_time >= ? AND start_time <= ? AND end_time >= ? AND end_time <= ?', start_time, end_time, start_time, end_time])
  end
  scope :binary_mask_grouped_by_listing, ->(day_mask) do
    joins(:listing)
      .merge(Listing.open_and_valid_now)
      .where('max_capacity >= min_units AND (available_mask & ? <> 0 )', day_mask)
      .where("INSTR(CONV(available_mask & ?,10,2), REPEAT('1', min_units)) > 0", day_mask)
      .group('listing_id')
  end
  
  scope :covers_interval, ->(start_time, end_time) do
    where(['start_time <= ? AND start_time <= ? AND end_time >= ?', start_time, end_time, end_time])
  end

  scope :binary_mask_grouped_by_listing_and_date, ->(day_mask, min_date) do
    binary_mask_grouped_by_listing(day_mask).where('start_time >= ?', min_date)
  end
 
  scope :by_date, ->(start_time) { where('DATE(start_time) = DATE(?)', start_time) }
  
  attr_accessor :date

  validate :check_overlapping_slots

  def short_title
    if listing.booking_per_hour?
      [start_time.strftime(I18n.t("availability.date_format")+" %H:%M"), end_time.strftime("%H:%M")].join("-")
    else
      start_time.strftime(I18n.t("availability.date_format"))
    end
  end

  before_validation :set_binary_masks

  def can_add_capacity?(extra_cap)
    return false if extra_cap > listing.capacity

    new_booked_mask = self.class.booked_mask_by_date(listing.bookings_per_hour.by_date(self.start_time), listing.capacity, extra_cap)
    binary_mask = calculate_binary_mask(start_time, end_time)
    binary_mask == (binary_mask & ~new_booked_mask)
  end

  def set_binary_masks
    if start_time.present? && end_time.present?
      self.binary_mask = calculate_binary_mask(start_time, end_time)
      if listing.booking_per_hour?
        new_booked_mask = self.class.booked_mask_by_date(listing.bookings_per_hour.by_date(self.start_time), listing.capacity)
        self.booked_mask = self.binary_mask & new_booked_mask
      else
        if listing.restricts_quantity?
          total_booked = overlapping_bookings.inject(0){ |s, x| s + [x.tx.listing_quantity.to_i, 1].max }
          self.booked_mask = total_booked >= listing.capacity ? self.binary_mask : 0
        else
          self.booked_mask = overlapping_bookings.count >= listing.capacity ? self.binary_mask : 0
        end
      end
      self.available_mask = self.binary_mask & ~self.booked_mask
      self.max_capacity = self.available_mask.to_s(2).split("0").map(&:length).max.to_i
    end
  end

  def overlapping_bookings
    listing.bookings_per_day.overlapping_with_date_period(self.start_time.to_date, self.start_time.to_date)
  end

  # MySQL does not support 128-bit bitwise operators
  def check_overlapping_slots
    overlapping_scope = listing.working_time_slots.by_date(self.start_time)
    overlapping_scope = overlapping_scope.where('id <> ?', self.id) unless new_record?
    if overlapping_scope.exists?
      not_overlapping = overlapping_scope.map do |slot|
        slot.binary_mask & self.binary_mask
      end.all?(&:zero?)
      if !not_overlapping
        errors.add(:base, I18n.t("availability.slot_overlaps", slot_1: self.short_title, slot_2: overlapping_scope.first.short_title))
      end
    end
  end

  def rebuild_masks
    save # implies set_binary_mask and set_available_mask
  end

  def description_with_price
    out = []
    out << MoneyViewUtils.to_humanized(price) if price.present?
    out << I18n.t("availability.max_capacity", capacity: capacity) if capacity.present? && capacity > 1
    out.join(", ")
  end

  def in_future?
    return false unless end_time
    tz = listing.auto_time_zone
    tz_time = tz.local(end_time.year, end_time.month, end_time.day, end_time.hour, end_time.min)
    tz_time > Time.zone.now
  end

  def current_available_mask
    tz = listing.auto_time_zone
    tz_start_time = tz.local(start_time.year, start_time.month, start_time.day, start_time.hour, start_time.min)
    tz_end_time = tz.local(end_time.year, end_time.month, end_time.day, end_time.hour, end_time.min)
    tz_now = (Time.zone.now.in_time_zone(tz).end_of_hour + 1.hour).beginning_of_hour
    adjusted_start = [tz_start_time, tz_now].max
    adjusted_mask = calculate_binary_mask(adjusted_start, tz_end_time)
    adjusted_mask & ~booked_mask
  end

  def current_max_capacity
    current_available_mask.to_s(2).split("0").map(&:length).max.to_i
  end

  def can_book_now?
    return false unless in_future?
    current_max_capacity > 0
  end

  def current_max_hours
    current_max_capacity * parts_per_hour
  end
end
