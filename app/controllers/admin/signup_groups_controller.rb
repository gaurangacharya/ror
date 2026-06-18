class Admin::SignupGroupsController < Admin::AdminBaseController
  before_action :set_navi

  def index
    @groups = resource_scope
  end

  def new
    @group = resource_scope.new
  end

  def create
    @group = resource_scope.create(group_params)
    if @group.errors.any?
      return render :edit
    end
    redirect_to action: :index
  end

  def edit
    @group = resource_scope.find(params[:id])
  end

  def update
    @group = resource_scope.find(params[:id])
    @group.update(group_params)
    redirect_to action: :index
  end

  def destroy
    @group = resource_scope.find(params[:id])
    @group.destroy
    redirect_to action: :index
  end

  private

  def set_navi
    @selected_left_navi_link = "signup_groups"
  end

  def group_params
    params.require(:signup_group).permit(
      :active,
      :title,
      :position,
      :is_default
    )
  end

  def resource_scope
    SignupGroup.sorted
  end
end
