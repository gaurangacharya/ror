require 'multi_logger'

module Fareharbor
  class ListingUpdater < BaseUpdater
    attr_reader :logger, :company, :item, :username

    # There is only one order type
    LISTING_SHAPE_ID = ENV['FAREHARBOR_LISTING_SHAPE_ID'] || ::APP_CONFIG.fareharbor_listing_shape_id
    # Person
    LISTING_UNIT_ID = ENV['FAREHARBOR_LISTING_UNIT_ID'] || ::APP_CONFIG.fareharbor_listing_unit_id

    CATEGORY_URL=  'other'

    MAX_TITLE_LENGTH = 60
    IMAGES_COUNT = 4
    LISTING_IS_OPEN = "0" # "1"

    def initialize(logger:, company:, item:, listing: nil, username: nil)
      @logger = logger
      @company = company
      @item = item
      @listing = listing
      @username = username
    end

    def run
      logger.info "=== STARTING LISTING UPDATE ==="
      logger.info "Company: #{company.shortname}, Item: #{item.pk} - #{item.name}"
      logger.info "Starting at: #{Time.current}"
      
      item_str = "company=#{company.shortname} item=#{item.pk}"
      
      logger.info "Associating person with local company"
      assing_person_to_local_company
      logger.info "✓ Person association completed"
      
      logger.info "Cleaning up orphaned listing images"
      orphaned_images = listing.listing_images.where(fareharbor_id: nil)
      if orphaned_images.any?
        logger.info "Found #{orphaned_images.count} orphaned images to delete"
        orphaned_images.destroy_all
        logger.info "✓ Deleted orphaned images"
      else
        logger.info "✓ No orphaned images found"
      end
      
      logger.info "Building listing attributes from FareHarbor data"
      listing.assign_attributes(build_attributes)
      logger.info "✓ Applied listing attributes"

      logger.info "Setting up listing associations"
      if !listing.community
        listing.community = community
        logger.info "✓ Set community: #{community.id}"
      else
        logger.info "✓ Community already set: #{listing.community.id}"
      end

      listing.author = author
      logger.info "✓ Set author: #{author.username} (ID: #{author.id})"

      if !listing.category
        listing.category = local_company ? local_company.category : category
        category_name = local_company ? local_company.category.display_name(:en) : category.display_name(:en)
        logger.info "✓ Set category: #{category_name}"
      else
        logger.info "✓ Category already set: #{listing.category.display_name(:en)}"
      end

      logger.info "Building listing images from FareHarbor"
      build_images
      logger.info "✓ Image processing completed"

      if listing.persisted?
        logger.info "✓ Found existing listing in database (ID: #{listing.id}) - #{item_str}"
        logger.info "Updating existing listing with latest data from FareHarbor"
      else
        logger.info "✗ Listing not found in database - #{item_str}"
        logger.info "Creating new listing record with data from FareHarbor"
        listing.assign_attributes(default_listing_attributes)
        logger.info "✓ Applied default listing attributes"
      end

      logger.info "Processing location data"
      unless listing.origin_loc.latitude.present?
        logger.info "Location coordinates missing, attempting to geocode"
        listing.origin_loc.search_and_fill_latlng
        if listing.origin_loc.latitude.present?
          logger.info "✓ Successfully geocoded location: #{listing.origin_loc.latitude}, #{listing.origin_loc.longitude}"
        else
          logger.warn "✗ Failed to geocode location for listing"
        end
      else
        logger.info "✓ Location coordinates already present: #{listing.origin_loc.latitude}, #{listing.origin_loc.longitude}"
      end

      logger.debug "Listing object details: #{listing.inspect}"
      
      logger.info "Saving listing to database"
      result = listing.save

      if result
        logger.info "✓ Successfully saved listing: #{item.name} (ID: #{listing.id})"
        logger.info "Listing title: #{listing.title}"
        logger.info "Listing price: #{listing.price_cents} #{listing.currency}"
        logger.info "Listing open: #{listing.open}"
        logger.info "Listing author: #{listing.author.username}"
        logger.info "Listing category: #{listing.category.display_name(:en)}"
      else
        logger.error "✗ Failed to save listing: #{item.name}"
        logger.error "Validation errors: #{listing.errors.full_messages}"
        listing.errors.each do |field, message|
          logger.error "  - #{field}: #{message}"
        end
      end

      logger.info "Cleaning up unused images"
      delete_images
      logger.info "✓ Image cleanup completed"
      
      logger.info "=== LISTING UPDATE COMPLETED ==="
      logger.info "Result: #{result ? 'SUCCESS' : 'FAILED'}"
      logger.info "Completed at: #{Time.current}"

      result
    end

    def item_images
      item.images.slice(0,IMAGES_COUNT)
    end

    def build_images
      images = item_images
      logger.info "Processing #{images.count} images from FareHarbor"
      
      images.each_with_index do |fareharbor_image, index|
        logger.info "[#{index + 1}/#{images.count}] Processing image: #{fareharbor_image[:pk]}"
        
        if existing_image = listing.listing_images.find_by(fareharbor_id: fareharbor_image[:pk])
          logger.info "✓ Image already exists (ID: #{existing_image.id}), skipping"
          next
        end
        
        logger.info "Creating new image record for FareHarbor ID: #{fareharbor_image[:pk]}"
        new_image = listing.listing_images.build(
          fareharbor_id: fareharbor_image[:pk],
          image: fareharbor_image[:image_cdn_url],
          image_downloaded: true
        )
        logger.info "✓ Image record created: #{fareharbor_image[:image_cdn_url]}"
      end
      
      logger.info "✓ Image processing completed for #{images.count} images"
    end

    def delete_images
      current_image_ids = item_images.map{|x| x[:pk]}
      images_to_delete = listing.listing_images.where.not(fareharbor_id: current_image_ids)
      
      if images_to_delete.any?
        logger.info "Found #{images_to_delete.count} images to delete: #{images_to_delete.map(&:id)}"
        logger.info "Current FareHarbor image IDs: #{current_image_ids}"
        images_to_delete.destroy_all
        logger.info "✓ Successfully deleted #{images_to_delete.count} unused images"
      else
        logger.info "✓ No images need to be deleted"
      end
    end

    def listing
      @listing ||= Listing.by_fareharbor_company(company).by_fareharbor_item(item).first_or_initialize
    end

    def default_listing_attributes
      {
        open: local_company ? local_company.new_listings_open : LISTING_IS_OPEN,
        unit_type: listing_unit.unit_type,
        quantity_selector: listing_unit.quantity_selector,
        unit_tr_key: listing_unit.name_tr_key,
        unit_selector_tr_key: listing_unit.selector_tr_key,
        currency: currency,
        restaurant_price: "$",
        call_for_price: "0",
        restaurant: "0",
        auto_confirm: "0",
        affiliate_pricing: "0",
        booking_mode: "none",
        min_units: "1.0",
        capacity: "0",
        ext_booking_url_direct: "0",
        instant_booking: "1",
        guest_only: "1",
        shipping_price_cents: "0",
        shipping_price_additional_cents: "0",
        pickup_enabled: "1",
        use_documents: "0",
        admin_rating: "20",
        # category_id: "311927",
        listing_shape_id: LISTING_SHAPE_ID,
        ext_booking_url: build_ext_booking_url,
        shape_name_tr_key: listing_shape.name_tr_key,
        action_button_tr_key: listing_shape.action_button_tr_key,
      }
    end

    def build_attributes
      new_location = build_listing_location
      title = item.name.slice(0, MAX_TITLE_LENGTH)

      {
        title: title,
        description_from_provider: item.description,
        price_cents: customer_prototype_lovest_price.try(:[], :total),
        currency: currency,
        origin: new_location[:address],
        origin_loc_attributes: new_location,
        fareharbor_updated_at: Time.current,
      }
    end

    def build_ext_booking_url
      query = {
        asn: 'fhdn',
        'asn-ref': 'ownoutdoors',
        'full-items': 'yes',
        flow: 'no',
      }

      "https://fareharbor.com/embeds/book/#{company.shortname}/items/#{item.pk}/?#{query.to_query}"
    end

    def build_listing_location
      location = location_present?(item.locations.first) ? item.locations.first : primary_location
      convert_location(location: location, location_type: 'origin_loc')
    end

    def primary_location
      company.primary_location
    end

    def currency
      company.currency.upcase
    end

    def customer_prototype_lovest_price
      # item.customer_prototypes.sort_by { |x| x[:total] }.first
      item.customer_prototypes.first
    end

    def listing_unit
      @listing_unit ||= ListingUnit.where(listing_shape_id: LISTING_SHAPE_ID).find(LISTING_UNIT_ID)
    end

    def listing_shape
      @listing_shape ||= ListingShape.find(LISTING_SHAPE_ID)
    end

    def category
      @category ||= Category.find_by(url: CATEGORY_URL)
    end

    def author
      @author ||= (Person.find_by(username: company.shortname) || create_author)
    end

    def create_author
      logger.info "Creating new person/author for FareHarbor company: #{company.shortname}"
      
      logger.info "Converting location data for person"
      location = convert_location(location: primary_location, location_type: 'person')
      if location
        logger.info "✓ Location data converted successfully"
      else
        logger.warn "✗ No location data available for person"
      end
      
      logger.info "Building person record with FareHarbor data"
      person = Person.new(
        fareharbor: true,
        community_id: community.id,
        password: SecureRandom.urlsafe_base64(16),
        username: company.shortname,
        given_name: company.name,
        family_name: company.name,
        display_name: company.name,
        description: company.about,
        skip_phone_validation: true,
        website_url: company.url,
      )
      logger.info "✓ Person record initialized"
      
      if location
        logger.info "Setting person location"
        person.build_location(location)
        logger.info "✓ Person location set"
      end
      
      logger.info "Creating community membership"
      person.community_memberships.build(
        community: community,
        status: 'accepted',
      )
      logger.info "✓ Community membership created"
      
      logger.info "Saving person to database"
      result = person.save

      if result
        logger.info "✓ Successfully created person: #{person.username} (ID: #{person.id})"
        logger.info "Person name: #{person.display_name}"
        logger.info "Person username: #{person.username}"
        logger.info "Person website: #{person.website_url}"
        logger.info "Person fareharbor flag: #{person.fareharbor}"
      else
        logger.error "✗ Failed to create person: #{company.shortname}"
        logger.error "Validation errors: #{person.errors.full_messages}"
        person.errors.each do |field, message|
          logger.error "  - #{field}: #{message}"
        end
      end

      person
    end

    def community
      Community.first
    end

    def assing_person_to_local_company
      if local_company && !local_company.person
        local_company.person = author
        local_company.save
      end
    end

    def local_company
      return @local_company if defined?(@local_company)

      local_company = FareharborCompany.find_by(shortname: company.shortname)

      @local_company = local_company
    end
  end
end
