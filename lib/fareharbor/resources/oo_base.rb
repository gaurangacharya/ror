module Fareharbor
  class OoBase < Spyke::Base
    class FareharborUserTokenEmpty < StandardError; end

    class << self
      def configuration
        Fareharbor.configuration
      end

      def set_connection(user_token)
        self.connection = Faraday.new(url: configuration.fareharbor_url) do |conn|
          conn.request :json
          conn.use Fareharbor::JSONParser
          conn.adapter Faraday.default_adapter
          conn.headers['X-FareHarbor-API-App'] = APP_CONFIG.fareharbor_app_token
          conn.headers['X-FareHarbor-API-User'] = user_token
        end
      end
    end
  end
end
