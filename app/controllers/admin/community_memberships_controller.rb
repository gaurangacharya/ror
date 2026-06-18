require 'csv'

class Admin::CommunityMembershipsController < Admin::AdminBaseController

  def index
    @selected_left_navi_link = "manage_members"
    @community = @current_community

    respond_to do |format|
      format.html do
        @memberships = CommunityMembership.where(community_id: @current_community.id, status: ["accepted", "banned", "pending_email_confirmation"])
                                           .includes(person: :emails)
                                           .paginate(page: params[:page], per_page: 50)
                                           .order("#{sort_column} #{sort_direction}")
        if params[:q].present?
          query = <<-SQL
          community_memberships.person_id IN
          (SELECT p.id FROM people p LEFT OUTER JOIN emails e ON e.person_id = p.id
           WHERE p.given_name like ? OR p.family_name like ? OR p.display_name like ? OR e.address like ?)
          SQL
          like_q = "%#{params[:q]}%"
          @memberships = @memberships.where(query, like_q, like_q, like_q, like_q)
        end
      end
      format.csv do
        all_memberships = CommunityMembership.where(community_id: @community.id)
                                              .where("status != 'deleted_user'")
                                              .includes(person: [:emails, :location])
        marketplace_name = if @community.use_domain
          @community.domain
        else
          @community.ident
        end

        self.response.headers["Content-Type"] ||= 'text/csv'
        self.response.headers["Content-Disposition"] = "attachment; filename=#{marketplace_name}-users-#{Date.today}.csv"
        self.response.headers["Content-Transfer-Encoding"] = "binary"
        self.response.headers["Last-Modified"] = Time.now.ctime.to_s

        self.response_body = Enumerator.new do |yielder|
          generate_csv_for(yielder, all_memberships, @community)
        end
      end
    end
  end

  def ban
    membership = CommunityMembership.find_by(id: params[:id], community_id: @current_community.id)

    if membership.person == @current_user
      flash[:error] = t("admin.communities.manage_members.ban_me_error")
      return redirect_to admin_community_community_memberships_path(@current_community)
    end

    membership.update(status: "banned")
    membership.update(admin: 0) if membership.admin == 1

    @current_community.close_listings_by_author(membership.person)

    if request.xhr?
      render json: {status: membership.status}
    else
      redirect_to admin_community_community_memberships_path(@current_community)
    end
  end

  def unban
    membership = CommunityMembership.find_by(id: params[:id], community_id: @current_community.id)
    membership.update(status: "accepted")
    if request.xhr?
      render json: {status: membership.status}
    else
      redirect_to admin_community_community_memberships_path(@current_community)
    end
  end

  def promote_admin
    if removes_itself?(params[:remove_admin], @current_user)
      render body: nil, status: 405
    else
      @current_community.community_memberships.where(person_id: params[:add_admin]).update_all("admin = 1")
      @current_community.community_memberships.where(person_id: params[:remove_admin]).update_all("admin = 0")

      render body: nil, status: 200
    end
  end

  def posting_allowed
    @current_community.community_memberships.where(person_id: params[:allowed_to_post]).update_all("can_post_listings = 1")
    @current_community.community_memberships.where(person_id: params[:disallowed_to_post]).update_all("can_post_listings = 0")

    render body: nil, status: 200
  end

  def pretend
    target_user = Person.where(community_id: @current_community.id, username: params[:id]).first
    if target_user
      sign_out
      IntercomHelper::ShutdownHelper.intercom_shutdown(session, cookies, request.host_with_port)
      sign_in target_user
      session[:admin_pretending] = params[:id]
      redirect_to homepage_without_locale_path
    else
      redirect_to action: :index
    end
  end

  def edit
    @membership = resource_scope.find(params[:id])
    unless @membership.person.person_white_label
      @membership.person.build_person_white_label
    end
  end

  def update
    @membership = resource_scope.find(params[:id])
    @membership.update(update_params)
    unless @membership.person.person_white_label
      @membership.person.build_person_white_label
    end
    render :edit
  end

  def premium_on
    membership = CommunityMembership.find_by(id: params[:id], community_id: @current_community.id)
    membership.person.update_columns(
      membership_status: Person::MEMBERSHIP_PREMIUM,
      membership_expires_at: 1.year.from_now
    )
    render json: {ok: 1}
  end

  def premium_off
    membership = CommunityMembership.find_by(id: params[:id], community_id: @current_community.id)
    membership.person.update_columns(
      membership_status: Person::MEMBERSHIP_FREE,
      membership_expires_at: nil
    )
    render json: {ok: 1}
  end

  private

  def generate_csv_for(yielder, memberships, community)
    # first line is column names
    header_row = %w{
      first_name
      last_name
      display_name
      username
      phone_number
      address
      email_address
      email_address_confirmed
      joined_at
      status
      is_admin
      accept_emails_from_admin
      language
      description
    }
    header_row.push("can_post_listings") if community.require_verification_to_post_listings
    yielder << header_row.to_csv(force_quotes: true)
    memberships.find_each do |membership|
      user = membership.person
      unless user.blank?
        user_data = [
          user.given_name,
          user.family_name,
          user.display_name,
          user.username,
          user.phone_number,
          user.location ? user.location.address : "",
          membership.created_at,
          membership.status,
          membership.admin,
          user.locale,
          user.description
        ]
        user_data.push(membership.can_post_listings) if community.require_verification_to_post_listings
        user.emails.each do |email|
          accept_emails_from_admin = user.preferences["email_from_admins"] && email.send_notifications
          yielder << user_data.clone.insert(6, email.address, !!email.confirmed_at).insert(11, !!accept_emails_from_admin).to_csv(force_quotes: true)
        end
      end
    end
  end

  def removes_itself?(ids, current_admin_user)
    ids ||= []
    ids.include?(current_admin_user.id) && current_admin_user.is_marketplace_admin?(@current_community)
  end

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
    when "posting_allowed"
      "can_post_listings"
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

  def resource_scope
    CommunityMembership.where(community_id: @current_community.id)
  end

  def update_params
    params.require(:community_membership).permit(
      person_attributes: [
        :id,
        :membership_status,
        :membership_expires_at,
        :reviews_disabled,
        :guest_type_pricing_enabled,
        person_white_label_attributes: [
          :id,
          :person_id,
          :custom_color1,
          :custom_color2,
          :slogan_color,
          :description_color,
          :logo,
          :wide_logo,
          :domain,
          :favicon,
          :email_sender,
          :design,
          :_destroy,
        ]
      ]
    )
  end
end
