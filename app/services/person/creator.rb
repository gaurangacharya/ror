class Person::Creator
  attr_reader :community, :params, :logger

  def initialize(community:, params:, logger:)
    @community = community
    @params = params
    @logger = logger
  end

  def create
    email = email_address
    new_person = nil
    cb_item = CbItem.find_by!(item_id: chargebee_plan_id)
    ActiveRecord::Base.transaction do
      new_person = Person.create!(create_params.merge(community_id: community.id, locale: APP_CONFIG.default_locale))
      Email.create!(address: email, send_notifications: true, person: new_person, community_id: community.id)

      new_person.set_default_preferences

      # By default no email consent is given
      new_person.preferences["email_from_admins"] = false
      new_person.cb_item = cb_item
      new_person.save

      CommunityMembership.create(person: new_person, community: community, status: "pending_email_confirmation")
    end
    if new_person && new_person.persisted? && new_person.emails.first
      Email.send_confirmation(new_person.emails.first, community)
    end
    new_person
  end

  private

  def create_params
    params.require(:person).permit(
      :given_name,
      :family_name,
      :username,
      :password,
      :password2,
      :phone_number,
      :signup_plan_id,
    )
  end

  def email_address
    email = params[:person][:email].downcase
    params[:person].delete(:email)
    email
  end

  def chargebee_plan_id
    id = params[:person][:chargebee_plan_id]
    params[:person].delete(:chargebee_plan_id)
    id
  end
end
