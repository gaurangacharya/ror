require 'multi_logger'

module Fareharbor
  class CompanyUpdater < BaseUpdater
    attr_reader :logger, :fareharbor_company,

    CATEGORY_URL=  'other'

    def initialize(logger:, fareharbor_company:)
      @logger = logger
      @fareharbor_company = fareharbor_company
    end

    def run
      logger.info "=== STARTING COMPANY UPDATE ==="
      logger.info "Company: #{fareharbor_company.shortname} (Currency: #{fareharbor_company.currency})"
      logger.info "Starting at: #{Time.current}"
      
      item_str = "company=#{fareharbor_company.shortname}"
      
      if company.persisted?
        logger.info "✓ Found existing company in database (ID: #{company.id}) - #{item_str}"
        logger.info "Updating existing company with latest data from FareHarbor API"
      else
        logger.info "✗ Company not found in database - #{item_str}"
        logger.info "Creating new company record with data from FareHarbor API"
        company.assign_attributes(default_company_attributes)
        logger.info "✓ Applied default company attributes"
      end

      logger.info "Applying current company attributes from FareHarbor API"
      company.assign_attributes(current_company_attributes)
      logger.info "✓ Applied current company attributes"

      logger.debug "Company object details: #{company.inspect}"
      
      logger.info "Saving company to database"
      result = company.save

      if result
        logger.info "✓ Successfully saved company: #{company.shortname} (ID: #{company.id})"
        logger.info "Company name: #{company.name}"
        logger.info "Company currency: #{company.currency}"
        logger.info "Company active: #{company.active}"
        logger.info "Company new_listings_open: #{company.new_listings_open}"
      else
        logger.error "✗ Failed to save company: #{company.shortname}"
        logger.error "Validation errors: #{company.errors.full_messages}"
        company.errors.each do |field, message|
          logger.error "  - #{field}: #{message}"
        end
      end
      
      logger.info "=== COMPANY UPDATE COMPLETED ==="
      logger.info "Result: #{result ? 'SUCCESS' : 'FAILED'}"
      logger.info "Completed at: #{Time.current}"

      result
    end

    def company
      @company ||= FareharborCompany.where(shortname: fareharbor_company.shortname).first_or_initialize
    end

    def default_company_attributes
      {
        active: false,
        new_listings_open: false,
        category: category,
      }
    end

    def current_company_attributes
      {
        name: fareharbor_company.name,
        currency: fareharbor_company.currency,
        affiliated_since: fareharbor_company.affiliated_since,
        summary: fareharbor_company.summary,
        about: fareharbor_company.about,
        booking_notes: fareharbor_company.booking_notes,
        faq: fareharbor_company.faq,
        intro: fareharbor_company.intro,
        address_street: fareharbor_company.address.try(:[], 'street'),
        address_city: fareharbor_company.address.try(:[], 'city'),
        address_province: fareharbor_company.address.try(:[], 'province'),
        address_country: fareharbor_company.address.try(:[], 'country'),
        address_postal_code: fareharbor_company.address.try(:[], 'postal_code'),
        billing_address_street: fareharbor_company.billing_address.try(:[], 'street'),
        billing_address_city: fareharbor_company.billing_address.try(:[], 'city'),
        billing_address_province: fareharbor_company.billing_address.try(:[], 'province'),
        billing_address_country: fareharbor_company.billing_address.try(:[], 'country'),
        billing_address_postal_code: fareharbor_company.billing_address.try(:[], 'postal_code'),
        primary_location_id: primary_location,
        primary_location_heading: fareharbor_company.primary_location_heading,
        url: fareharbor_company.url,
        facebook_url: fareharbor_company.facebook_url,
        instagram_url: fareharbor_company.instagram_url,
        tripadvisor_url: fareharbor_company.tripadvisor_url,
        twitter_url: fareharbor_company.twitter_url,
        yelp_url: fareharbor_company.yelp_url,
        youtube_url: fareharbor_company.youtube_url,
        pinterest_url: fareharbor_company.pinterest_url,
        health_and_safety_policy: fareharbor_company.health_and_safety_policy,
        open_hours: fareharbor_company.open_hours,
      }
    end

    def primary_location
      convert_location(location: fareharbor_company.primary_location)
    end

    def category
      @category ||= Category.find_by(url: CATEGORY_URL)
    end
  end
end
