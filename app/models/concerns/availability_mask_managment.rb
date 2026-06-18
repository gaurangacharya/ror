module AvailabilityMaskManagment
  extend ActiveSupport::Concern

  HALF_HOUR = 30
  QUARTER_HOUR = 15

  def current_available_mask_to_hours_string
    mask_to_hours_string(current_available_mask)
  end

  def mask_to_hours(mask)
    if mask.is_a?(Array)
      mask.map{|part| single_mask_to_hours(part) }.flatten
    else
      single_mask_to_hours(mask)
    end
  end

  def single_mask_to_hours(mask)
    last = nil
    result = []
    last_number = listing.slot_15min_increment? ? 95 : 47
    0.upto(last_number).each do |offset|
      bit = mask & (1 << offset)
      if bit != 0
        if last && last[:end] == offset
          last[:end] = offset+1
        else
          last = {start: offset, end: offset+1}
          result << last
        end
      end
    end
    result.map do |row|
      {
        start: {
          offset: row[:start],
          hour: row[:start] / parts_per_hour,
          min: (row[:start] % parts_per_hour) * single_increment
        },
        end: {
          offset: row[:end] ,
          hour: row[:end] / parts_per_hour,
          min: (row[:end] % parts_per_hour) * single_increment
        },
      }
    end
  end

  def mask_to_hours_string(mask)
    mask_to_hours(mask).map do |x|
      start_value = self.class.format_time(x[:start][:hour], x[:start][:min])
      end_value = self.class.format_time(x[:end][:hour], x[:end][:min])
      [start_value, end_value].join("-")
    end.join(", ")
  end

  def available_mask_options_for_select(date, slot_number)
    day_options = []
    mask_to_hours(current_available_mask).each do |row|
      row[:start][:offset].upto(row[:end][:offset]).each do |offset|
        hour = offset / parts_per_hour
        minute = (offset % parts_per_hour) * single_increment
        value = sprintf("%02d:%02d", hour == 24 ? 0 : hour, minute)
        min_hours = [listing.min_units.to_f, listing.fixed_units.to_f].max
        duration = (row[:end][:offset] - offset) / parts_per_hour.to_f
        hour_hash = {value: value, name: self.class.format_time(hour, minute), slot: slot_number, disabled_start: duration < min_hours, min_hours: min_hours }
        if offset == row[:end][:offset]
          hour_hash[:disabled] = true
          hour_hash[:slot_end] = true
          if hour == 24
            hour_hash[:next_day] = (date + 1).to_s
          end
        end
        day_options << hour_hash
      end
      slot_number += 1
    end
    return [slot_number, day_options]
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def format_time(hour, min)
      Time.parse(sprintf("%02d:%02d", hour, min)).strftime("%l:%M%P")
    end

    def booked_mask_by_date(bookings_sope, listing_capacity, add_capacity = nil)
      add_quantity = add_capacity ? [add_capacity, 1].max - 1 : 0
      overall_mask = []
      bookings_sope.each do |booking|
        booked_quantity = [booking.tx.listing_quantity.to_i, 1].max
        booking.binary_mask.to_s(2).split(//).reverse.each_with_index do |bit, index|
          overall_mask[index] ||= 0
          overall_mask[index] += bit.to_i * booked_quantity
        end
      end
      booked_mask = 0
      overall_mask.each_with_index do |bit_count, index|
        bit = bit_count + add_quantity >= listing_capacity ? 1 : 0
        booked_mask += bit << index
      end
      booked_mask
    end
  end
end
