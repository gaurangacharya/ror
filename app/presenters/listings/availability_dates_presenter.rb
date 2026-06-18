class Listings::AvailabilityDatesPresenter
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

  def availability_background_slots
    slot_map = Hash.new(0)
    avail_map = Hash.new(0)
    min_slot_map = Hash.new(false)
    mask_titles = Hash.new

    working_slots = listing.working_time_slots.interval(params[:start], params[:end]).each do |slot|
      date = slot.start_time.to_date
      avail_map[date] |= slot.current_available_mask
      slot_map[date] |= slot.binary_mask
      min_slot_map[date] ||= slot.current_max_hours >= listing.min_units
      mask_titles[date] ||= []
      mask_titles[date] << slot.current_available_mask_to_hours_string
    end

    est_tz_today = ActiveSupport::TimeZone["America/New_York"].today

    slot_map.keys.map do |date|
      work_mask = slot_map[date]
      available_mask = avail_map[date]
      has_minimum_slot = min_slot_map[date]

      class_name = if work_mask == 0 || date < est_tz_today
        'day-availability-none'
      elsif available_mask == work_mask && has_minimum_slot || listing.booking_per_day_or_night? && available_mask > 0
        'day-availability-free'
      elsif available_mask == 0 || !has_minimum_slot
        'day-availability-full'
      else
        'day-availability-partial'
      end
      {
        start: date.strftime('%Y-%m-%dT%H:%M:%S'),
        end: (date+1).strftime('%Y-%m-%dT%H:%M:%S'),
        allDay: true,
        className: class_name,
        rendering: 'background',
        description: mask_titles[date].select(&:present?).join(", ")
      }
    end
  end

  def current_user_listing_author?
    @current_user_listing_author ||= current_user && (current_user == listing.author || current_user.has_admin_rights?(current_community))
  end
end
