require 'fareharbor'

Fareharbor.configure do |config|
  config.app_token  = ENV['FAREHARBOR_APP_TOKEN'] || APP_CONFIG.fareharbor_app_token
  #config.user_token = ENV['FAREHARBOR_USER_TOKEN_USD'] || APP_CONFIG.fareharbor_user_token_usd
end
