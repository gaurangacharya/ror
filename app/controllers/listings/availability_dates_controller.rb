class Listings::AvailabilityDatesController < ApplicationController
  before_action :set_presenter
  respond_to :js
  layout false

  def index
    render json: @presenter.availability_background_slots.to_json
  end

  private

  def set_presenter
    @presenter = Listings::AvailabilityDatesPresenter.new(
      current_user: @current_user,
      params: params,
      current_community: @current_community
    )
  end
end
