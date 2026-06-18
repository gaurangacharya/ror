class Admin::FingerprintsController < Admin::AdminBaseController
  before_action :set_navi

  def index
    @fingerprints = BrowserFingerprint
      .where(["hash_code like ?", "%"+params[:code].to_s+"%"])
      .order('updated_at desc')
      .paginate(page: params[:page], per_page: 50)
  end

  def show
    @fingerprint = BrowserFingerprint.find(params[:id])
  end

private
  def set_navi
    @selected_left_navi_link = "fingerprints"
  end
end
