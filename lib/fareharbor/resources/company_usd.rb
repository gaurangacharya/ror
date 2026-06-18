module Fareharbor
  class CompanyUsd < CompanyBase
    uri 'companies/(:id)/'
    set_connection(APP_CONFIG.fareharbor_user_token_usd)

    def items
      Fareharbor::ItemUsd.where(shortname: self.shortname)
    end
  end
end
