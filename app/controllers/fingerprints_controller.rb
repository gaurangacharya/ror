class FingerprintsController < ApplicationController
  layout false
  def create
    components = {}
    params[:components].each do |row|
      components[row['key']] = row['value']
    end
    BrowserFingerprint.record_usage(params[:hash_code], components, request.remote_ip, current_user)
    render body: "OK"
  end
end
