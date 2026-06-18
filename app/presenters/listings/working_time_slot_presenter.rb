class Listings::WorkingTimeSlotPresenter
  include DatepickerLocalizationHelper
  include Rails.application.routes.url_helpers

  attr_reader :current_user, :params, :current_community

  def initialize(current_user:, params:, current_community:)
    @current_user = current_user
    @params = params
    @current_community = current_community
  end

  def listing
    @listing ||= Listing.find(params[:listing_id])
  end

  def calendar_working_time_slots
    resource_scope.interval(params[:start], params[:end]).map{|slot| to_hash(slot)}
  end

  def time_slot
    @current_time_slot || resource_scope.build
  end

  def new_time_slot(slot_params)
    slot = resource_scope.new(slot_params)
    slot.calendar = true
    @current_time_slot = slot
  end

  def find_time_slot
    @current_time_slot = resource_scope.find(params[:id])
  end

  def find_time_slot_or_existing_day
    @current_time_slot = existing_day_slot || resource_scope.find(params[:id])
  end

  def existing_day_slot
    if listing.booking_per_day_or_night? && params[:date].present?
      listing.working_time_slots.by_date(params[:date]).first
    end
  end

  def current_user_listing_author?
    @current_user_listing_author ||= current_user && (current_user == listing.author || current_user.has_admin_rights?(current_community))
  end

  def datepicker
    {
      locale: I18n.locale,
      localized_dates: datepicker_localized_dates,
    }
  end

  def time_slot_option(hour, minute)
    { value: format("%02d:%02d", hour, minute), label: Listing::WorkingTimeSlot.format_time(hour, minute) }
  end

  def time_slot_options
    result = []
    (0..24).each do |hour|
      result.push(time_slot_option(hour, 0))

      break if hour == 24

      if listing.slot_15min_increment
        result.push(time_slot_option(hour, 15))
        result.push(time_slot_option(hour, 30))
        result.push(time_slot_option(hour, 45))
      else
        result.push(time_slot_option(hour, 30))
      end
    end
    result
  end

  private

  def resource_scope
    listing.working_time_slots.calendar
  end

  def to_hash(slot)
    result = {
      start: slot.start_time.strftime('%Y-%m-%dT%H:%M:%S'),
      end: slot.end_time.strftime('%Y-%m-%dT%H:%M:%S'),
      allDay: listing.booking_per_day_or_night?
    }
    if current_user_listing_author? 
      result.merge!(
        url: edit_listing_working_time_slot_path(listing_id: listing.id, id: slot.id),
        urlRemote: true,
        className: (slot.available_mask == 0 ? 'day-availability-full' : 'cal-working-time-slots'),
        rendering: listing.booking_per_day_or_night? ? 'background' : '',
      )
    end
    result
  end
end
