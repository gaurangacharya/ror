class ChargebeesController < ApplicationController
  skip_before_action :cannot_access_without_confirmation, :ensure_user_belongs_to_community, only: [:checkout, :checkout_new, :success]

  def new
    @person = Person.new
    @signup_plan = SignupPlan.find(params[:signup_plan_id])
  end

  def create_person
    @signup_plan = SignupPlan.find(params[:person][:signup_plan_id])
    @person = Person::Creator.new(community: @current_community, params: params, logger: Rails.logger).create
    if @person.persisted?
      sign_in(:person, @person)
      flash[:notice] = t("layouts.notifications.login_successful", person_name: view_context.link_to(PersonViewUtils.person_display_name_for_type(@person, "first_name_only"), person_path(@person))).html_safe
    end
    render layout: false
  end

  def checkout
    if !current_person
      return redirect_to '/'
    end
    @person = current_person
  end

  def checkout_new
    hosted_page = HostedPage.new(
      params: params,
      success_path: 'https://memberdeals.com/ownoutdoors/?login=1', # success_chargebee_url
      person: current_person,
    ).checkout_new
    render json: hosted_page
  end

  # There are no links between HostedPage and Event in ChargeBee.
  # So we are forced to rely on this stupid success endpoint.
  def success
    Person::SetChargebee.new(person: current_person).run
    return redirect_to person_path(locale: I18n.locale, username: current_person.username)
  end

  private

  class HostedPage
    attr_reader :params, :plan_id, :period_unit, :success_path, :person

    def initialize(params:, success_path:, person:)
      @params = params
      @person = person
      @plan_id = person.cb_item.item_id
      @period_unit = params[:period_unit]
      @success_path = success_path
    end

    def checkout_new
      item_price = item_prices.first
      result = ChargeBee::HostedPage.checkout_new_for_items(
        subscription_items: [
          {
            item_price_id: item_price.id,
            quantity: 1
          }
        ],
        customer: {
          first_name: person.given_name,
          last_name: person.family_name,
          phone: person.phone_number,
          email: person.emails.first&.address,
        },
        redirect_url: success_path,
      )
      person.update_column(:chargebee_hosted_page_id, result.hosted_page.id)
      result.hosted_page
    end

    private

    def item_prices
      ChargeBee::ItemPrice.list(
        'item_id[is]': plan_id,
        'period_unit[is]': period_unit
      ).map{|x| x.item_price}
    end

    def person
      @person ||= Person.find(params[:person_id])
    end
  end
end
