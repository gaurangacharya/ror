module EnsureGuestUser
  extend ActiveSupport::Concern

  def ensure_logged_in_or_guest
    return if @current_user.present?

    if session[:guest_person_id].present?
      @current_user = Person.find(session[:guest_person_id])
    else
      ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_this_page")
    end
  end

  def create_guest_person_and_pseido_sign_up
    if !@current_user
      @current_user = create_guest_person
      session[:guest_person_id] = @current_user.id.to_s
    end
    @current_user
  end

  def create_guest_person
    guest = Person.build_guest(@current_community)
    guest.store_guest_info(params, @current_community)
    guest
  end

  def ensure_fake_current_user
    @current_user ||= Person.build_guest(@current_community)
  end

  def guest_person_session_from_token
    session[:guest_person_id] = params[:token] if params[:token].present?

    true
  end
end
