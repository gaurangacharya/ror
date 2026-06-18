class Listings::BookedTimeSlotPresenter
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

  def booked_time_slots
    
    scope = if listing.booking_per_hour?
              listing.bookings_per_hour.includes(tx: :starter).overlapping_with_period(params[:start], params[:end])
            else
              listing.bookings_per_day.includes(tx: :starter).overlapping_with_date_period(params[:start], params[:end])
            end
    if !current_user_listing_author?
      if @current_user
        scope.for_buyer(@current_user.id).map{|slot| to_map_hash(booking)}.flatten
      else
        []
      end
    else
      scope.map{|booking| to_map_hash(booking)}.flatten
    end
  end

  def current_user_listing_author?
    @current_user_listing_author ||= current_user && (current_user == listing.author || current_user.has_admin_rights?(current_community))
  end

  private

  def to_hash(booking)
    result = {
      start: booking.start_time.strftime('%Y-%m-%dT%H:%M:%S'),
      end: booking.end_time.strftime('%Y-%m-%dT%H:%M:%S')
    }
    if current_user_listing_author? 
      result.merge!(
        title: PersonViewUtils.person_display_name(booking.tx.starter, @current_community),
        url: person_transaction_path(person_id: @current_user.id, id: booking.tx.id)
      )
    else
      result.merge!(
        title: I18n.t("admin.communities.transactions.status.#{booking.tx.current_state}"),
        url: person_transaction_path(person_id: booking.tx.starter.id, id: booking.tx.id)
      )
    end
    result
  end

  def to_map_hash(booking)
    if booking.per_hour?
      to_hash(booking)
    else
      (booking.start_on...booking.end_on).map do |date|
        tmp = booking.dup
        tmp.start_time =   date.at_beginning_of_day
        tmp.end_time = (date+1).at_beginning_of_day
        to_hash(tmp)
      end
    end
  end

end
