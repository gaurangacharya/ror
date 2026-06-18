module Fareharbor
  class Configuration
    attr_accessor :fareharbor_url, :app_token, :user_token

    def initialize
      @fareharbor_url = 'https://fareharbor.com/api/external/v1'
    end
  end
end
