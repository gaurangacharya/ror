require 'securerandom'
class Admin::CouponsController < Admin::AdminBaseController
  before_action :set_navi

  def index
    @coupons = Coupon
      .where(community_id: @current_community.id)
      .order('created_at desc')
      .paginate(page: params[:page], per_page: 50)
  end

  def show
    @coupon = Coupon.where(community_id: @current_community.id).find(params[:id])
  end

  def create
    coupon = Coupon.new
    coupon.community_id = @current_community.id
    coupon.code = params[:code].present? ? params[:code] : Coupon.generate_code
    coupon.value = params[:value]
    coupon.valid_until = parse_date(params[:valid_until])
    coupon.save!
    redirect_to action: :index
  end

  def destroy
    @coupon = Coupon.where(community_id: @current_community.id).find(params[:id])
    @coupon.valid_until = 1.day.ago
    @coupon.save
    redirect_to action: :index
  end

  def update
    @coupon = Coupon.where(community_id: @current_community.id).find(params[:id])
    @coupon.code = params[:coupon][:code]
    @coupon.value = params[:coupon][:value]
    @coupon.valid_until = parse_date(params[:coupon][:valid_until])
    @coupon.save!
    redirect_to action: :show, id: @coupon.id
  end

private
  def set_navi
    @selected_left_navi_link = "coupons"
  end

  def parse_date(value)
    Date.strptime(value.to_s, "%m/%d/%Y")
  rescue => e
  end

end
