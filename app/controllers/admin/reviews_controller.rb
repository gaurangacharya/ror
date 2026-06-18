class Admin::ReviewsController < Admin::AdminBaseController
  respond_to :html
  before_action :set_left_navi_link

  def index
    @reviews = resource_scope.paginate(page: params[:page], per_page: 50)
  end

  def new
    @review = resource_scope.new
  end

  def create
    @review = resource_scope.new(create_params)
    @review.community = @current_community
    if @review.save
      redirect_to action: :index
    else
      render :new
    end
  end

  def edit
    @review = resource_scope.find(params[:id])
  end

  def update
    @review = resource_scope.find(params[:id])
    if @review.update(create_params)
      redirect_to action: :index
    else
      render :edit
    end
  end

  def destroy
    @review = resource_scope.find(params[:id])
    @review.destroy
    redirect_to action: :index
  end

  private

  def resource_scope
    Review.where(community: @current_community)
  end

  def set_left_navi_link
    @selected_left_navi_link = "reviews"
  end

  def create_params
    params.required(:review).permit(:title, :content, :author)
  end
end
