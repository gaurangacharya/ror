require 'csv'

class Admin::PremiumMembersController < Admin::AdminBaseController

  def index
    @selected_left_navi_link = "premium_members"
    @community = @current_community
    @people = Person
      .where(community_id: @current_community.id)
      .includes(:emails)
      .where('signup_charge_id is not null')
      .paginate(page: params[:page], per_page: 50)
      .order("#{sort_column} #{sort_direction}")
  end

  private

  def sort_column
    case params[:sort]
    when "name"
      "people.given_name"
    when "display_name"
      "people.display_name"
    when "email"
      "emails.address"
    when "join_date"
      "created_at"
    else
      "created_at"
    end
  end

  def sort_direction
    #prevents sql injection
    if params[:direction] == "asc"
      "asc"
    else
      "desc" #default
    end
  end
end
