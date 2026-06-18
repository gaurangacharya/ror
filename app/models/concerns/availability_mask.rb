module AvailabilityMask
  extend ActiveSupport::Concern

  HALF_HOUR = 30
  QUARTER_HOUR = 15

  HOUR_HEIGHT = 44

  def single_increment
    @single_increment ||= listing.slot_15min_increment? ? QUARTER_HOUR : HALF_HOUR
  end

  def parts_per_hour
    @parts_per_hour ||= listing.slot_15min_increment? ? 4 : 2
  end

  def calculate_binary_mask(starts, ends)
    result = 0
    day_start = starts.beginning_of_day
    time = starts
    while time < ends
      offset = (time - day_start) / single_increment.minutes
      result |= 1 << offset
      time += single_increment.minutes
    end
    result
  end

  def display_working_time_slot
    {
      start: self.start_time.strftime("%l:%M%P"),
      end: self.end_time.strftime("%l:%M%P"),
      height: (self.end_time - self.start_time).to_f / 3600 * HOUR_HEIGHT,
      top: time_offset(self.start_time) * HOUR_HEIGHT / parts_per_hour.to_f
    }
  end

  def display_booking
    display_working_time_slot.merge({
      transaction_id: self.transaction_id,
      person: self.tx.starter,
      status: self.tx.current_state
    })
  end

  def time_offset(time)
    (time - time.at_beginning_of_day) / single_increment.minutes
  end
end
