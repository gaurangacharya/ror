class FareharborImportCompanyListingsJob < ApplicationJob
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.first)
  end

  def perform(community_id, fareharbor_company_id)
    company = ::FareharborCompany.find(fareharbor_company_id)
    ::Fareharbor::Updater.new.import_listings_single_company(company.shortname, company.currency)
  end
end
