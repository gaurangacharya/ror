module Fareharbor
  class ItemGbp < ItemBase
    uri 'companies/:shortname/items/'
    set_connection(APP_CONFIG.fareharbor_user_token_gbp)
  end
end
