
class FareharborListingUpdateFromUrl
  def run
    Listing.fareharbor.find_each do |listing|
      listing.update_fareharbor_from_url
    end
  end
end

namespace :fareharbor do
  task :listing_update_from_url => :environment do |t, args|
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger = Logger.new('/dev/null')
    FareharborListingUpdateFromUrl.new.run
  end

  task :import_listings_active_companies => :environment do |t, args|
    Fareharbor::Updater.new.import_listings_active_companies
  end

  task :import_companies_usd => :environment do |t, args|
    Fareharbor::Updater.new.import_companies('USD')
  end

  task :import_companies_eur => :environment do |t, args|
    Fareharbor::Updater.new.import_companies('EUR')
  end

  task :import_companies_gbp => :environment do |t, args|
    Fareharbor::Updater.new.import_companies('GBP')
  end
end
