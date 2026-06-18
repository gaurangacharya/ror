class TransactionPresenter
  ADDITIONAL_LISTINGS_PER_PAGE = 6

  attr_reader :current_person, :params

  def initialize(current_person:, params:)
    @current_person = current_person
    @params = params
  end

  def tx
    @tx ||= Transaction.find_by(id: params[:id])
  end

  def listing
    @listing ||= tx.listing
  end

  def author
    @author ||= listing.author
  end

  def additional_listings
    @additional_listings ||= Listing.open_and_valid_now
      .where(author: listing&.author)
      .paginate(page: params[:page], per_page: ADDITIONAL_LISTINGS_PER_PAGE)
      .order(updated_at: :desc)
  end

  def is_author
    author == current_person || is_admin
  end

  def is_admin
    current_person && current_person.community_membership.admin?
  end

  def booking
    @booking ||= tx.booking
  end

  def booking_time
    res = I18n.l(booking.start_time.to_date, format: :long_with_abbr_day_name)
    res += ' - '

    if !listing.fixed_units.present?
      res += I18n.t("transactions.initiate.start_end_time",
                start_time: I18n.l(booking.start_time, format: :hours_only),
                end_time: I18n.l(booking.end_time, format: :hours_only))
      res += I18n.t("transactions.initiate.duration_in_hours", count: booking.duration)
    else
      res += I18n.t("transactions.initiate.start_time",
                start_time: I18n.l(booking.start_time, format: :hours_only))
    end

    res
  end
end
