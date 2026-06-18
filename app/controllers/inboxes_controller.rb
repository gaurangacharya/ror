class InboxesController < ApplicationController
  before_action do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_inbox")
  end
  before_action :set_presenter

  def show
    inbox_rows = @presenter.index
    if request.xhr?
      render :partial => "inbox_row",
        :collection => inbox_rows, :as => :conversation,
        locals: {
          payments_in_use: @current_community.payments_in_use?
        }
    else
      render locals: {
        inbox_rows: inbox_rows,
        payments_in_use: @current_community.payments_in_use?
      }
    end
  end

  def export
    respond_to do |format|
      format.csv do
        self.response.headers["Content-Type"] ||= 'text/csv'
        self.response.headers["Content-Disposition"] = "attachment; filename=transactions-#{Date.today}.csv"
        self.response.headers["Content-Transfer-Encoding"] = "binary"
        self.response.headers["Last-Modified"] = Time.now.ctime.to_s

        self.response_body = @presenter.generate_csv
      end
    end
  end

  private

  def set_presenter
    @presenter = InboxPresenter.new(
      current_person: current_person,
      params: params,
      community: @current_community,
      person_white_label: @person_white_label,
    )
  end
end
