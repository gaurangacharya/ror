# == Schema Information
#
# Table name: docusign_authorizations
#
#  id            :integer          not null, primary key
#  community_id  :integer
#  person_id     :string(22)
#  access_token  :string(1024)
#  refresh_token :string(1024)
#  expires_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'net/http'
require 'uri'
require 'mime/types'
class DocusignAuthorization < ApplicationRecord
  belongs_to :community
  belongs_to :person

  def self.rest_host
    if APP_CONFIG.docusign_mode.to_s == "development"
      "account-d.docusign.com"
    else
      "account.docusign.com"
    end
  end

  def self.base_host
    if APP_CONFIG.docusign_mode.to_s == "development"
      "https://demo.docusign.net"
    else
      "https://www.docusign.net"
    end
  end

  def authorized?
    true
  end

  def api_client
    configuration = DocuSign_eSign::Configuration.new
    configuration.host = DocusignAuthorization.base_host
    client = DocuSign_eSign::ApiClient.new(configuration)
    client.configure_jwt_authorization_flow(
      File.join(Rails.root, "config/docusign_private_key"),
      DocusignAuthorization.rest_host,
      APP_CONFIG.docusign_integrator_key,
      APP_CONFIG.docusign_username, 3600)
    client
  end
end
