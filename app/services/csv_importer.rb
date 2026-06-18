require 'csv'

class CSVImporter
  attr_accessor :errors, :total_users, :listings, :people

  def initialize(community, file)
    @community = community
    @file = file
    @errors = []
    @translations = CommunityTranslation.all.each_with_object({}){|row, result| result[row.translation_key] = row.translation }
    @custom_fields = CustomField.all.index_by{|row| row.name }
    @categories = Category.all.index_by{|row| row.display_name(I18n.locale) }
    @shapes = ListingShape.all.to_a
    @listings = []
    @people = []
  end

  def process
    CSV.parse(@file.read, headers: true).each_with_index do |row, index|

        row = row.to_h.with_indifferent_access
        Person.transaction do
          import_row(row, index)
        end
        listing = @listings.last
        listing.delta = true
        listing.save
    rescue StandardError => e
        @errors << [index, [e.inspect, e.message, e.backtrace[0]].join(" ")]

    end
  end

  def import_row(row, index)
    return unless row['Email'].present?

    person = create_person(row, index)
    return unless person

    @people << person
    listing = make_listing(person, row, index) if row['Listing Title'].present?
    @listings << listing if listing
  end

  # Given Name,Family Name,Email,Username,Password,Profile Type
  def create_person(params, index)
    person = Person.new({
        username: params['Username'],
        community_id: @community.id,
        display_name: params['Business Name'],
        locale: 'en',
        password: params['Password'],
        is_vendor: params['Seller Type'] == 'Business',
        website_url: params['Website URL'],
        phone_number: params['Phone'],
        description: params['About Business']
      })
    email_address = params['Email'].downcase.strip
    allowed_and_available = @community.email_allowed?(email_address) && Email.email_available?(email_address, @community.id)
    unless allowed_and_available
      @errors << [index, "The email #{email_address} is already in use"]
      return nil
    end

    username_exists = Person.where(community_id: @community.id, username: params['Username']).exists?
    if username_exists
      @errors << [index, "The username #{params['Username']} is already in use"]
      return nil
    end

    email = Email.new(:person => @person, :address => email_address, :send_notifications => true, community_id: @community.id)
    person.emails << email
    person.inherit_settings_from(@community)
    person.set_default_preferences
    person.skip_phone_validation = true
    person.save!

    membership = CommunityMembership.new(:person => person, :community => @community, :consent => @community.consent, status: 'pending_email_confirmation')
    membership.save!
    if person.is_vendor
      person.image = File.new(Rails.root+"app/assets/images/gray_shop_logo.png")
      person.save
    end

    location = Location.new(address: params['Address'], location_type: 'person')
    location.person = person
    location.search_and_fill_latlng
    location.save

    person
  end


  # Listing Type,Listing Title,Price,Description,Category,Unit Type,List Filter,Condition,Pickup/Dropoff Options,Address,Images
  def make_listing(author, params, index)
    shape = find_shape(params["Listing Type"])
    unless shape
      @errors << [index, "Missing shape #{params['Listing Type']}"]
      return
    end

    listing_unit = find_unit(shape, params['Unit Type'])

    listing = Listing.new
    listing.community_id = @community.id
    listing.title = params["Listing Title"]
    listing.description = params["Description"]
    listing.price_cents = params["Price"].to_f * 100
    listing.call_for_price = params["Price"].to_s.downcase.strip == "call for price" || params["Price"].to_s.downcase.strip == "call"
    listing.currency = @community.currency
    listing.author = author
    listing.category = find_category(params["Category"])

    listing.listing_shape = shape
    listing.transaction_process_id = shape.transaction_process_id
    listing.availability = shape.availability
    listing.shape_name_tr_key = shape.name_tr_key
    listing.action_button_tr_key = shape.action_button_tr_key

    listing.unit_type = listing_unit&.unit_type
    listing.quantity_selector = listing_unit&.quantity_selector
    listing.unit_tr_key = listing_unit&.name_tr_key
    listing.unit_selector_tr_key = listing_unit&.selector_tr_key

    location = Location.new(address: params['Address'], location_type: 'origin_loc')
    location.search_and_fill_latlng
    listing.origin_loc = location
    listing.save!

    if params["Images"].present?
      params["Images"].split("|").each_with_index do |url, index|
        ListingImage.create(image: URI.open(url), listing: listing, position: index, image_downloaded: 1, author_id: author.id)
      end
    end

    ['Activity Types','Condition','Pick-up/Drop-off Options', 'Seller Type', 'Charter Duration'].each do |cf_name|
      add_custom_field_options(listing, cf_name, params[cf_name], index)
    end

    listing
  end

  def find_shape(name)
    @shapes.detect{|shape| @translations[shape.name_tr_key] == name }
  end

  def find_category(name)
    @categories[name.to_s.strip]
  end

  def add_custom_field_options(listing, name, values, index)
    return unless values.present?

    custom_field = @custom_fields[name]
    unless custom_field
      @errors << [index, "Missing custom field \"#{name}\""]
      return
    end

    options = values.split("|").map do |value|
      custom_field.options.detect{|opt| opt.title.strip == value.strip }
    end.compact.map(&:id)
    if field_value = listing.custom_field_value_factory(custom_field.id, options)
      field_value.save
    end
  end

  def find_unit(shape, name)
    shape.listing_units.detect{|u| u.unit_type.to_s == name || @translations[u.name_tr_key] == name }
  end

  IMPORT_SAMPLE_DATA = {
    "Business Name" => "ACME",
    "Email" => "acme+05@mailinator.com",
    "Username" => "acme05",
    "Password" => "123123",
    "Seller Type" => "Business",
    "Website URL" => "http://google.com/",
    "Phone" => "212-555-44-44",
    "About Business" => "Some text about business",
    "Listing Type" => "Create Listing",
    "Listing Title" => "Import me!",
    "Price" => "123.45",
    "Description" => "Demo import http://goo.gl",
    "Category" => "CHARTERS",
    "Unit Type" => "2 hours",
    "Activity Types" => "Tours & Guides",
    "Condition" => "Excellent (New)|Fair",
    "Pick-up/Drop-off Options" => "Store/Business Location|Home Location",
    "Charter Duration" => "Other",
    "Address" => "13705 NE 12th Ave North Miami FL 33161 USA",
    "Images" => "https://d2hxfhf337f2kp.cloudfront.net/ownoutdoors/ownOutDoors_category-Boating_BG.jpg"
  }

  def reference_package(p = nil)
    p ||= Axlsx::Package.new
    p.workbook.add_worksheet(:name => "Import Template") do |sheet|
      sheet.add_row(IMPORT_SAMPLE_DATA.keys)
      sheet.add_row(IMPORT_SAMPLE_DATA.values)
    end

    p.workbook.add_worksheet(:name => "Listing Shapes (Types)") do |sheet|
      ListingShape.all.each do |shape|
        sheet.add_row([@translations[shape.name_tr_key], "Unit Types"])
        shape.listing_units.each do |unit|
          type_name = unit.unit_type == 'custom' ? @translations[unit.name_tr_key] : unit.unit_type
          sheet.add_row(["", type_name])
        end
        sheet.add_row([])
      end
    end

    p.workbook.add_worksheet(:name => "Categories") do |sheet|
      Category.where(community_id: @community.id, parent: nil).each do |category|
        sheet.add_row([category.display_name(I18n.locale), ''])
        category.subcategories.each do |subcat|
          sheet.add_row(["", subcat.display_name(I18n.locale)])
        end
        sheet.add_row([])
      end
    end

    p.workbook.add_worksheet(:name => "Checkbox Fields") do |sheet|
      CheckboxField.where(community_id: @community.id).each do |custom_field|
        sheet.add_row([custom_field.name, ''])
        custom_field.options.each do |option|
          sheet.add_row(["", option.title])
        end
        sheet.add_row([])
      end
    end

    p.workbook.add_worksheet(:name => "Dropdown Fields") do |sheet|
      DropdownField.where(community_id: @community.id).each do |custom_field|
        sheet.add_row([custom_field.name, ''])
        custom_field.options.each do |option|
          sheet.add_row(["", option.title])
        end
        sheet.add_row([])
      end
    end

    p
  end

end
