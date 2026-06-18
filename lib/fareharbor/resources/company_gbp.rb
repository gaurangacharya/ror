module Fareharbor
  class CompanyGbp < CompanyBase
    uri 'companies/(:id)/'
    set_connection(APP_CONFIG.fareharbor_user_token_gbp)

    def items
      Fareharbor::ItemGbp.where(shortname: self.shortname)
    end
  end
end
