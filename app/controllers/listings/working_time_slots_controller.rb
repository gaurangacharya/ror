class Listings::WorkingTimeSlotsController < ApplicationController
  before_action :set_presenter
  respond_to :js
  layout false

  before_action :only => [ :new, :create, :edit, :update ] do |controller|
    controller.ensure_current_user_is_listing_author t("layouts.notifications.only_listing_author_can_edit_a_listing")
  end

  def index
    render json: @presenter.calendar_working_time_slots.to_json
  end

  def new
    if @presenter.existing_day_slot
      edit
    end
  end

  def create
    time_slot = @presenter.new_time_slot(slot_params)
    if multi_date?
      @error_list = []
      multi_date_params.each do |slot|
        new_slot = @presenter.new_time_slot(slot)
        unless new_slot.save
          @error_list += new_slot.errors.to_a 
        end
      end
      if @error_list.present?
        render :new
      else
        render :create
      end
    elsif time_slot.save
      render :create
    else
      @error_list = time_slot.errors.to_a
      render :new
    end
  end

  def edit
    @presenter.find_time_slot_or_existing_day
  end

  def update
    time_slot = @presenter.find_time_slot
    update_params = multi_date_params.first
    if time_slot.update(update_params)
      render :update
    else
      render :edit
    end
  end

  def destroy
    time_slot = @presenter.find_time_slot
    time_slot.destroy
    render :update
  end

  protected

  def ensure_current_user_is_listing_author(error_message)
    return if @presenter.current_user_listing_author?
    flash[:error] = error_message
    redirect_to @presenter.listing and return
  end

  private

  def set_presenter
    @presenter = Listings::WorkingTimeSlotPresenter.new(
      current_user: @current_user,
      params: params,
      current_community: @current_community
    )
    if @presenter.listing.booking_per_day_or_night? && params[:listing_working_time_slot].present?
      params[:listing_working_time_slot][:start_time] = '00:00'
      params[:listing_working_time_slot][:end_time] = '24:00'
    end
  end

  def slot_params
    {
      start_time: params[:listing_working_time_slot][:start_time],
      end_time:   params[:listing_working_time_slot][:end_time],
    }
  end

  def multi_date?
    true
  end

  def multi_date_params
    tz = ActiveSupport::TimeZone.new('UTC')
    date_format = I18n.t("time.formats.to_datepicker")+" %H:%M"
    start_time = params[:listing_working_time_slot][:start_time].to_s[/\d\d:\d\d$/]
    end_time = params[:listing_working_time_slot][:end_time].to_s[/\d\d:\d\d$/]
    if !start_time.present? || !end_time.present?
      return []
    end
    params[:listing_working_time_slot][:date].split(/,\s*/).map do |date_string|
      {
        start_time: tz.strptime(date_string+" "+start_time, date_format),
        end_time: tz.strptime(date_string+" "+end_time, date_format)
      }
    end
  end
end
