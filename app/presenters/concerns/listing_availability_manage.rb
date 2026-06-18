module ListingAvailabilityManage
  def availability_enabled
    listing.availability.to_sym == :booking
  end

  def booking_dates_start
    1.day.ago.to_date
  end

  def booking_dates_end
    if stripe_in_use
      APP_CONFIG.stripe_max_booking_date.days.from_now.to_date
    else
      12.months.from_now.to_date
    end
  end

  def blocked_dates_result
    if availability_enabled

      get_blocked_dates(
        start_on: booking_dates_start,
        end_on: booking_dates_end,
        community: current_community,
        user: @current_user,
        listing: listing)
    else
      Result::Success.new([])
    end
  end

  def booking_dates_end_midnight
    DateUtils.to_midnight_utc(booking_dates_end)
  end

  def get_blocked_dates(start_on:, end_on:, community:, user:, listing:)
    Result::Success.new(dates_to_ts_set(start_on..end_on).subtract(DateTimeSlotService.query_available_slots(listing.id, start_on, end_on)))
  end

  def has_no_future_dates?
    DateTimeSlotService.query_available_slots(listing.id, booking_dates_start, booking_dates_end).empty?
  end

  def dates_to_ts_set(dates)
    Set.new(dates.map { |d| DateUtils.to_midnight_utc(d) })
  end

  include DatepickerLocalizationHelper

  def datepicker_per_day_or_night_setup(blocked_dates)
    {
      locale: I18n.locale,
      localized_dates: datepicker_localized_dates,
      listing_quantity_selector: listing.booking_quantity_selector,
      blocked_dates: blocked_dates.map { |d| d.to_i },
      end_date: booking_dates_end_midnight.to_i,
    }
  end

  def booking_per_hour_start_time
    date_to_time_utc(booking_dates_start)
  end

  def booking_per_hour_end_time
    date_to_time_utc(booking_dates_end + 1.day)
  end

  def availability_options_for_select
    slot_map = Hash.new
    listing.working_time_slots.interval(booking_per_hour_start_time, booking_per_hour_end_time).each do |slot|
      (slot_map[slot.start_time.to_date] ||= []) << slot
    end

    result = {}

    slot_map.each do |date, slot_list|
      slot_number = 0
      day_options = []
      slot_list.each do |slot|
        slot_number, new_day_options = slot.available_mask_options_for_select(date, slot_number)
        day_options.concat(new_day_options)
      end
      result[date.to_s] = day_options if day_options.present?
    end

    blocked_dates = []
    start = booking_per_hour_start_time
    while start < booking_per_hour_end_time
      day = start.to_date.to_s
      blocked_dates.push start.to_date unless result.key?(day)
      start += 1.day
    end
    [result, blocked_dates]
  end

  def datepicker_per_hour_setup
    per_hour_options, blocked_dates = availability_options_for_select
    {
      locale: I18n.locale,
      localized_dates: datepicker_localized_dates,
      listing_quantity_selector: listing.booking_quantity_selector,
      blocked_dates: blocked_dates.map { |d| date_to_time_utc(d).to_i },
      end_date: booking_dates_end_midnight.to_i,
      options_for_select: per_hour_options,
      min_hours: listing.min_units,
      parts_per_hour: listing.slot_15min_increment? ? 4 : 2,
      fixed_hours: listing.fixed_units,
    }
  end

  def booking?
    listing.booking?
  end

  def booking_per_hour?
    listing.booking_per_hour?
  end

  def booking_per_day_or_night?
    listing.booking_per_day_or_night?
  end

  def quantity_per_day_or_night?
    listing.booking_per_day_or_night?
  end

  def calendar_working_time_slots
    listing.working_hours_for_calendar_as_json
  end

  private

  def working_time_slots
    listing.working_hours_new_set if params[:listing_just_created] || !listing.per_hour_ready
    listing.working_hours_as_json
  end

  def time_slot_options
    result = []
    (0..24).each do |x|
      value = format("%02d:00", x)
      name = I18n.locale == :en ? Time.parse("#{x}:00").strftime("%l:00 %P") : value
      result.push(value: value, label: name)
    end
    result
  end

  def date_to_time_utc(d)
    Time.utc(d.year, d.month, d.day)
  end

end
