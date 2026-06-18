module DateTimeSlotService
  module_function

  def all_days_available?(listing_id, start_on, end_on)
    slots = query_available_slots(listing_id, start_on, end_on)
    (start_on...end_on).all?{|date| slots.include?(date) }
  end

  def query_available_slots(listing_id, start_on, end_on)
    query_date_slots(listing_id, start_on, end_on).where('available_mask > 0').map do |ts|
      ts.start_time.to_date
    end
  end

  def query_booked_timeslots(listing_id, start_on, end_on)
    query_date_slots(listing_id, start_on, end_on).where('available_mask = 0').map do |ts|
      ts.start_time.to_date
    end
  end

  def all_days_available_qty?(listing_id, start_on, end_on, qty)
    qty = [qty, 1].max
    slots = query_available_slots(listing_id, start_on, end_on)
    has_slots = (start_on...end_on).all?{|date| slots.include?(date) }
    return false unless has_slots

    listing = Listing.find(listing_id)
    max_booked = 0
    (start_on..end_on).each do |date|
      slots = query_date_slots(listing_id, date, date+1)
      slots.each do |slot|
        if listing.restricts_quantity?
          total_booked = slot.overlapping_bookings.inject(0){ |s, x| s + [x.tx.listing_quantity.to_i, 1].max }
        else
          total_booked = slot.overlapping_bookings.count
        end
        if total_booked > max_booked
          max_booked = total_booked
        end
      end
    end

    max_booked + qty <= listing.capacity
  end

  def query_date_slots(listing_id, start_on, end_on)
    Listing::WorkingTimeSlot
      .where(listing_id: listing_id)
      .where('start_time >= ?', start_on.to_time.at_beginning_of_day)
      .where('end_time <= ?', end_on.to_time.at_end_of_day)
      .order('start_time ASC')
  end


  def initiate_booking(tx_id)
    tx = Transaction.find tx_id
    booking = tx.booking
    if tx.listing.booking_per_day_or_night?
      (booking.start_on...booking.end_on).each do |date|
        tx.listing.working_time_slots.by_date(date).each do |slot|
          slot.update(available_mask: 0, booked_mask: slot.available_mask)
        end
      end
    end
  end

  def accept_booking(tx_id)
    initiate_booking(tx_id)    
  end

  def reject_booking(tx_id)
    tx = Transaction.find tx_id
    booking = tx.booking
    if tx.listing.booking_per_day_or_night?
      (booking.start_on...booking.end_on).each do |date|
        tx.listing.working_time_slots.by_date(date).each do |slot|
          slot.update(available_mask: slot.binary_mask, booked_mask: 0)
        end
      end
    end
  end
end
