require 'securerandom'
class Admin::SignupPlansController < Admin::AdminBaseController
  before_action :set_navi

  def index
    @plans = resource_scope
  end

  def new
    @plan = resource_scope.new
  end

  def create
    @plan = resource_scope.create(plan_params)
    if @plan.errors.any?
      return render :edit
    end
    redirect_to action: :index
  end

  def edit
    @plan = resource_scope.find(params[:id])
  end

  def update
    @plan = resource_scope.find(params[:id])
    @plan.update(plan_params)
    redirect_to action: :index
  end

  def destroy
    @plan = resource_scope.find(params[:id])
    @plan.destroy
    redirect_to action: :index
  end

  private

  def set_navi
    @selected_left_navi_link = "signup_plans"
  end

  def plan_params
    params.require(:signup_plan).permit(
      :code,
      :active,
      :title,
      :subtitle,
      :price_title,
      :plan_body,
      :position,
      :signup_group_id,
      :signup_button_text,
      :create_account_button_text
    )
  end

  def resource_scope
    SignupPlan.sorted
  end
end
