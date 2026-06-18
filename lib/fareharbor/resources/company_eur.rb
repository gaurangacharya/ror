module Fareharbor
  class CompanyEur < CompanyBase
    uri 'companies/(:id)/'
    set_connection(APP_CONFIG.fareharbor_user_token_eur)

    def items
      Fareharbor::ItemEur.where(shortname: self.shortname)
    end
  end
end
