module Fareharbor
  class ItemUsd < ItemBase
    uri 'companies/:shortname/items/'
    set_connection(APP_CONFIG.fareharbor_user_token_usd)
  end
end
