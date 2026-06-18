module FareharborExtension
  extend ActiveSupport::Concern

  # https://fareharbor.com/embeds/book/paddlethefloridakeys/items/64394/?sheet=231341&asn=fhdn&asn-ref=ownoutdoors&full-items=yes&flow=no
  FAREHARBOR_URL_RE = /https\:\/\/fareharbor\.com\/embeds\/book\/([\w\d\-\_]*)\/items\/(\d*)[\/\?]/

  def self.included(base)
    base.scope :fareharbor_in_extended_url, -> { where('listings.ext_booking_url LIKE ?', '%fareharbor.com%') }
    base.scope :by_fareharbor_company, -> (fareharbor_company) do
      where(fareharbor_company_id: fareharbor_company.shortname)
    end
    base.scope :by_fareharbor_item, -> (fareharbor_item) do
      where(fareharbor_item_id: fareharbor_item.pk)
    end
    base.scope :fareharbor_import_since_yesterday, -> do
      where('fareharbor_updated_at >= ?', (Time.current - 1.day).beginning_of_day)
    end
  end

  def fareharbor_company_class
    "::Fareharbor::Company#{currency.downcase.capitalize}".constantize
  end

  def fareharbor_company
    @fareharbor_company ||= fareharbor_company_class.find(fareharbor_company_id)
  end

  def fareharbor_item
    @fareharbor_item ||= fareharbor_company.items.detect{ |item| item.pk.to_s == fareharbor_item_id }
  end

  def update_fareharbor_from_url
    if (fareharbor_company_from_url)
      update_columns(
        fareharbor_company_id: fareharbor_company_from_url,
        fareharbor_item_id: fareharbor_item_from_url,
      )
    else
      puts "listing: #{id} cannot get company from: #{ext_booking_url}"
    end
  end

  def fareharbor_company_from_url
    fareharbor_url_match.try(:[], 1)
  end

  def fareharbor_item_from_url
    fareharbor_url_match.try(:[], 2)
  end

  def fareharbor_url_match
    ext_booking_url.match(FAREHARBOR_URL_RE)
  end

  def update_from_fareharbor_item!
    listing_updater = ::Fareharbor::ListingUpdater.new(
      logger: Rails.logger,
      company: fareharbor_company,
      item: fareharbor_item,
      listing: self,
    )
    listing_updater.run
  end
end
