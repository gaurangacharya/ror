module Fareharbor
  class ItemEur < ItemBase
    uri 'companies/:shortname/items/'
    set_connection(APP_CONFIG.fareharbor_user_token_eur)
  end
end
