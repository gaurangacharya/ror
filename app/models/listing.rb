# encoding: utf-8
# == Schema Information
#
# Table name: listings
#
#  id                              :integer          not null, primary key
#  uuid                            :binary(16)       not null
#  community_id                    :integer          not null
#  author_id                       :string(255)
#  category_old                    :string(255)
#  title                           :string(255)
#  times_viewed                    :integer          default(0)
#  language                        :string(255)
#  created_at                      :datetime
#  updates_email_at                :datetime
#  updated_at                      :datetime
#  last_modified                   :datetime
#  sort_date                       :datetime
#  listing_type_old                :string(255)
#  description                     :text(16777215)
#  origin                          :string(255)
#  destination                     :string(255)
#  valid_until                     :datetime
#  delta                           :boolean          default(TRUE), not null
#  open                            :boolean          default(TRUE)
#  share_type_old                  :string(255)
#  privacy                         :string(255)      default("private")
#  comments_count                  :integer          default(0)
#  subcategory_old                 :string(255)
#  old_category_id                 :integer
#  category_id                     :integer
#  share_type_id                   :integer
#  listing_shape_id                :integer
#  transaction_process_id          :integer
#  shape_name_tr_key               :string(255)
#  action_button_tr_key            :string(255)
#  price_cents                     :integer
#  currency                        :string(255)
#  quantity                        :string(255)
#  unit_type                       :string(32)
#  quantity_selector               :string(32)
#  unit_tr_key                     :string(64)
#  unit_selector_tr_key            :string(64)
#  deleted                         :boolean          default(FALSE)
#  require_shipping_address        :boolean          default(FALSE)
#  pickup_enabled                  :boolean          default(FALSE)
#  shipping_price_cents            :integer
#  shipping_price_additional_cents :integer
#  availability                    :string(32)       default("booking")
#  per_hour_ready                  :boolean          default(FALSE)
#  featured                        :boolean          default(FALSE)
#  call_for_price                  :boolean          default(FALSE)
#  booking_mode                    :string(255)      default("hour")
#  min_units                       :float(24)        default(1.0)
#  deposit_cents                   :integer
#  document_id                     :integer
#  use_documents                   :boolean
#  affiliate_pricing               :boolean          default(TRUE)
#  auto_confirm                    :boolean          default(TRUE)
#  capacity                        :integer          default(1)
#  min_quantity                    :integer          default(1)
#  max_quantity                    :integer
#  ext_booking_url                 :string(1024)
#  instant_booking                 :boolean          default(FALSE)
#  guest_only                      :boolean          default(FALSE)
#  admin_rating                    :integer          default(0)
#  restaurant                      :boolean          default(FALSE)
#  restaurant_price                :integer          default("$")
#  ext_booking_url_direct          :boolean          default(FALSE)
#  pdf_file_name                   :string(255)
#  pdf_content_type                :string(255)
#  pdf_file_size                   :integer
#  pdf_updated_at                  :datetime
#  embed_document                  :string(1024)
#  musement_widget_id              :string(255)
#  hide_price                      :boolean          default(FALSE)
#  fareharbor_company_id           :string(255)
#  fareharbor_item_id              :string(255)
#  fareharbor_updated_at           :datetime
#  description_from_provider       :text(16777215)
#  description_closing             :text(16777215)
#  show_min_quantity               :boolean          default(TRUE)
#  show_max_quantity               :boolean          default(TRUE)
#  name_on_reservation             :boolean
#  slot_15min_increment            :boolean
#  fixed_units                     :float(24)
#  gift_card                       :boolean          default(FALSE)
#
# Indexes
#
#  homepage_query                           (community_id,open,sort_date,deleted)
#  homepage_query_valid_until               (community_id,open,valid_until,sort_date,deleted)
#  index_listings_on_category_id            (old_category_id)
#  index_listings_on_community_id           (community_id)
#  index_listings_on_fareharbor_company_id  (fareharbor_company_id)
#  index_listings_on_fareharbor_item_id     (fareharbor_item_id)
#  index_listings_on_listing_shape_id       (listing_shape_id)
#  index_listings_on_new_category_id        (category_id)
#  index_listings_on_open                   (open)
#  index_listings_on_uuid                   (uuid) UNIQUE
#  person_listings                          (community_id,author_id)
#  updates_email_listings                   (community_id,open,updates_email_at)
#

class Listing < ApplicationRecord

  include ApplicationHelper
  include ActionView::Helpers::TranslationHelper
  include Rails.application.routes.url_helpers
  include ManageAvailabilityPerHour
  include FareharborExtension
  include RansackSearchable

  has_attached_file :pdf, processors: [ :to_image ], styles: {original: { format: :png } }, validate_media_type: false
  validates_attachment :pdf, content_type: { content_type: ['application/pdf', 'application/x-pdf', "image/jpeg", "image/png", "image/pjpeg", "image/x-png"] }

  belongs_to :author, :class_name => "Person", :foreign_key => "author_id"
  belongs_to :community

  has_many :listing_images, -> { where("error IS NULL").order("position") }, :dependent => :destroy

  has_many :conversations
  has_many :comments, :dependent => :destroy
  has_many :custom_field_values, :dependent => :destroy
  has_many :custom_dropdown_field_values, :class_name => "DropdownFieldValue"
  has_many :custom_checkbox_field_values, :class_name => "CheckboxFieldValue"

  has_one :location, :dependent => :destroy
  has_one :origin_loc, -> { where('location_type = ?', 'origin_loc') }, :class_name => "Location", :dependent => :destroy
  has_one :destination_loc, -> { where('location_type = ?', 'destination_loc') }, :class_name => "Location", :dependent => :destroy
  accepts_nested_attributes_for :origin_loc, :destination_loc

  has_and_belongs_to_many :followers, :class_name => "Person", :join_table => "listing_followers"

  has_one :document, :dependent => :destroy

  belongs_to :category
  has_many :working_time_slots, ->{ ordered },  dependent: :destroy
  accepts_nested_attributes_for :working_time_slots, reject_if: :all_blank, allow_destroy: true

  belongs_to :listing_shape

  has_many :tx, class_name: 'Transaction'
  has_many :bookings, through: :tx
  has_many :bookings_per_hour, ->{ per_hour_blocked }, through: :tx, source: :booking
  has_many :bookings_per_day, ->{ per_day_blocked }, through: :tx, source: :booking
  has_many :testimonials, through: :tx
  has_many :listing_hide_from_people
  has_many :hide_from_people, through: :listing_hide_from_people, source: :person
  has_many :listing_show_for_people
  has_many :show_for_people, through: :listing_show_for_people, source: :person
  has_many :add_ons, class_name: "ListingAddOn", dependent: :destroy
  accepts_nested_attributes_for :add_ons, reject_if: :all_blank, allow_destroy: true
  has_and_belongs_to_many :taxes, association_foreign_key: :listing_tax_id
  accepts_nested_attributes_for :taxes, reject_if: :reject_blank_tax_or_service_fee, allow_destroy: true
  has_and_belongs_to_many :service_fees, association_foreign_key: :listing_service_fee_id
  accepts_nested_attributes_for :service_fees, reject_if: :reject_blank_tax_or_service_fee, allow_destroy: true

  monetize :price_cents, :allow_nil => true, with_model_currency: :currency
  monetize :visitor_price_cents, :allow_nil => true, with_model_currency: :visitor_price_currency
  monetize :shipping_price_cents, allow_nil: true, with_model_currency: :currency
  monetize :shipping_price_additional_cents, allow_nil: true, with_model_currency: :currency
  monetize :deposit_cents, allow_nil: true, with_model_currency: :currency

  scope :within_geo_dist, -> (lat, lng, max_distance) do
    joins(:origin_loc).where("FD_GEODIST(latitude, longitude, :lat, :lng) < :dist", lat: lat, lng: lng, dist: max_distance)
  end
  scope :open_and_valid_now, -> { where(["deleted = 0 AND open = 1 AND (valid_until IS NULL OR valid_until > ?)", DateTime.now]) }
  scope :closed, -> { where(open: false) }

  before_validation :set_valid_until_time

  validates_presence_of :author_id
  validates_length_of :title, :in => 2..60, :allow_nil => false

  scope :for_community, ->(community_id) { where(community_id: community_id) }

  belongs_to :document

  RESTAURANT_PRICES = {
    RESTAURANT_PRICE_LOWEST = :'$' => 0,
    RESTAURANT_PRICE_LOW = :'$-$$' => 1,
    RESTAURANT_PRICE_MIDDLE = :'$$ - $$$' => 2,
    RESTAURANT_PRICE_HIGH = :'$$$ - $$$$' => 3,
  }

  enum restaurant_price: RESTAURANT_PRICES

  after_save ThinkingSphinx::RealTime.callback_for(:listing)

  attr_accessor :delete_pdf
  before_validation { pdf.clear if delete_pdf == '1' }

  before_create :set_sort_date_to_now
  def set_sort_date_to_now
    self.sort_date ||= Time.now
  end

  before_create :set_updates_email_at_to_now
  def set_updates_email_at_to_now
    self.updates_email_at ||= Time.now
  end

  # Guest type pricing methods (formerly Ladera-specific)
  def has_guest_type_pricing?
    author&.guest_type_pricing_enabled? || author&.person_white_label&.ladera_enabled?
  end

  # Legacy method for backwards compatibility
  alias_method :is_ladera_listing?, :has_guest_type_pricing?

  def has_visitor_pricing?
    visitor_price_cents.present? && visitor_price_cents > 0
  end

  def price_for_guest_type(guest_type)
    case guest_type&.to_s
    when 'hotel_guest'
      price # Hotel guests get the standard price
    when 'visitor'
      visitor_price.present? ? visitor_price : price
    else
      price # Default to regular price
    end
  end

  def display_price_for_guest_type(guest_type)
    case guest_type&.to_s
    when 'hotel_guest'
      price > 0 ? price : 'Complimentary' # Show "Complimentary" only if standard price is $0
    when 'visitor' 
      visitor_price.present? ? visitor_price : price
    else
      price
    end
  end

  def uuid_object
    if self[:uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:uuid])
    end
  end

  def uuid_object=(uuid)
    self.uuid = UUIDUtils.raw(uuid)
  end

  before_create :add_uuid
  def add_uuid
    self.uuid ||= UUIDUtils.create_raw
  end

  before_validation do
    # Normalize browser line-breaks.
    # Reason: Some browsers send line-break as \r\n which counts for 2 characters making the
    # 5000 character max length validation to fail.
    # This could be more general helper function, if this is needed in other textareas.
    self.description = description.gsub("\r\n","\n") if self.description
  end
  validates_length_of :description, :maximum => 5000, :allow_nil => true
  validates_presence_of :category
  validates_inclusion_of :valid_until, :allow_nil => :true, :in => DateTime.now..DateTime.now + 7.months
  validates_numericality_of :price_cents, :only_integer => true, :greater_than_or_equal_to => 0, :message => "price must be numeric", :allow_nil => true

  def self.currently_open(status="open")
    status = "open" if status.blank?
    case status
    when "all"
      where([])
    when "open"
      where(["open = '1' AND (valid_until IS NULL OR valid_until > ?)", DateTime.now])
    when "closed"
      where(["open = '0' OR (valid_until IS NOT NULL AND valid_until < ?)", DateTime.now])
    end
  end

  def visible_to?(current_user, current_community, pretending = false)
    # DEPRECATED
    #
    # Consider removing the `visible_to?` method.
    #
    # Reason: Authorization logic should be in the controller layer (filters etc.),
    # not in the model layer.
    #
    ListingVisibilityGuard.new(self, current_community, current_user, pretending).visible?
  end

  # sets the time to midnight
  def set_valid_until_time
    if valid_until
      self.valid_until = valid_until.utc + (23-valid_until.hour).hours + (59-valid_until.min).minutes + (59-valid_until.sec).seconds
    end
  end

  # Overrides the to_param method to implement clean URLs
  def to_param
    self.class.to_param(id, title)
  end

  def self.to_param(id, title)
    "#{id}-#{title.to_url}"
  end

  def self.find_by_category_and_subcategory(category)
    Listing.where(:category_id => category.own_and_subcategory_ids)
  end

  # Returns true if listing exists and valid_until is set
  def temporary?
    !new_record? && valid_until
  end

  def update_fields(params)
    update_attribute(:valid_until, nil) unless params[:valid_until]
    update(params)
  end

  def closed?
    !open? || (valid_until && valid_until < DateTime.now)
  end

  # Send notifications to the users following this listing
  # when the listing is updated (update=true) or a
  # new comment to the listing is created.
  def notify_followers(community, current_user, update)
    followers.each do |follower|
      unless follower.id == current_user.id
        if update
          MailCarrier.deliver_now(PersonMailer.new_update_to_followed_listing_notification(self, follower, community))
        else
          MailCarrier.deliver_now(PersonMailer.new_comment_to_followed_listing_notification(comments.last, follower, community))
        end
      end
    end
  end

  def image_by_id(id)
    listing_images.find_by_id(id)
  end

  def prev_and_next_image_ids_by_id(id)
    listing_image_ids = listing_images.collect(&:id)
    ArrayUtils.next_and_prev(listing_image_ids, id);
  end

  def has_image?
    !listing_images.empty?
  end

  def icon_name
    category.icon_name
  end

  # The price symbol based on this listing's price or community default, if no price set
  def price_symbol
    price ? price.symbol : MoneyRails.default_currency.symbol
  end

  def answers_for_field_name(custom_field_name)
    custom_field = community.custom_fields.detect{|cf| cf.name == custom_field_name }
    return "" unless custom_field
    answer_for(custom_field)&.text_value
  end

  def answer_for(custom_field)
    custom_field_values.find { |value| value.custom_field_id == custom_field.id }
  end

  def unit_type
    Maybe(read_attribute(:unit_type)).to_sym.or_else(nil)
  end

  def init_origin_location(location)
    if location.present?
      build_origin_loc(location.attributes)
    else
      build_origin_loc()
    end
  end

  def ensure_origin_loc
    build_origin_loc unless origin_loc
  end

  def custom_field_value_factory(custom_field_id, answer_value)
    question = CustomField.find(custom_field_id)

    answer = question.with_type do |question_type|
      case question_type
      when :dropdown
        option_id = answer_value.is_a?(Array) ? answer_value.first.to_i : answer_value.to_i
        answer = DropdownFieldValue.new
        answer.custom_field_option_selections = [CustomFieldOptionSelection.new(:custom_field_value => answer,
                                                                                :custom_field_option_id => option_id,
                                                                                :listing_id => self.id)]
        answer
      when :text
        answer = TextFieldValue.new
        answer.text_value = answer_value
        answer
      when :numeric
        answer = NumericFieldValue.new
        answer.numeric_value = ParamsService.parse_float(answer_value)
        answer
      when :checkbox
        answer = CheckboxFieldValue.new
        answer.custom_field_option_selections = answer_value.map { |value|
          CustomFieldOptionSelection.new(:custom_field_value => answer, :custom_field_option_id => value, :listing_id => self.id)
        }
        answer
      when :date_field
        answer = DateFieldValue.new
        answer.date_value = Time.utc(answer_value["(1i)"].to_i,
                                     answer_value["(2i)"].to_i,
                                     answer_value["(3i)"].to_i)
        answer
      else
        raise ArgumentError.new("Unimplemented custom field answer for question #{question_type}")
      end
    end

    answer.question = question
    answer.listing_id = self.id
    return answer
  end

  # Note! Requires that parent self is already saved to DB. We
  # don't use association to link to self but directly connect to
  # self_id.
  def upsert_field_values!(custom_field_params)
    custom_field_params ||= {}

    # Delete all existing
    custom_field_value_ids = self.custom_field_values.map(&:id)
    CustomFieldOptionSelection.where(custom_field_value_id: custom_field_value_ids).delete_all
    CustomFieldValue.where(id: custom_field_value_ids).delete_all

    field_values = custom_field_params.map do |custom_field_id, answer_value|
      custom_field_value_factory(custom_field_id, answer_value) unless is_answer_value_blank(answer_value)
    end.compact

    # Insert new custom fields in a single transaction
    CustomFieldValue.transaction do
      field_values.each(&:save!)
    end
  end

  def is_answer_value_blank(value)
    if value.is_a?(Hash)
      value["(3i)"].blank? || value["(2i)"].blank? || value["(1i)"].blank?  # DateFieldValue check
    else
      value.blank?
    end
  end

  def reorder_listing_images(params, user_id)
    listing_image_ids =
      if params[:listing_images]
        params[:listing_images].collect { |h| h[:id] }.select { |id| id.present? }
      else
        logger.error("Listing images array is missing", nil, {params: params})
        []
      end

    ListingImage.where(id: listing_image_ids, author_id: user_id).update_all(listing_id: self.id)

    if params[:listing_ordered_images].present?
      params[:listing_ordered_images].split(",").each_with_index do |image_id, position|
        ListingImage.where(id: image_id, author_id: user_id).update_all(position: position+1)
      end
    end
  end

  def logger
    @logger ||= SharetribeLogger.new(:listing, logger_metadata.keys).tap { |logger|
      logger.add_metadata(logger_metadata)
    }
  end

  def logger_metadata
    { listing_id: id }
  end

  BOOKING_MODES = %w(hour day night)

  def booking?
    BOOKING_MODES.include?(booking_mode)
  end

  def booking_per_hour?
    'hour' == booking_mode
  end

  def booking_per_day?
    'day' == booking_mode
  end

  def booking_per_night?
    'night' == booking_mode
  end

  def booking_per_day_or_night?
    booking_per_day? || booking_per_night?
  end

  def availability
    booking? ? "booking" : "none"
  end

  def booking_quantity_selector
    booking? ? booking_mode : quantity_selector
  end

  def need_quantity_input?
    pricing_rule[:mode] == :quantity && !call_for_price
  end

  def restricts_quantity?
    need_quantity_input? && min_quantity.present? && max_quantity.present?
  end

  def enough_quantity?(qty)
    !restricts_quantity? || min_quantity <= qty.to_i && qty.to_i <= max_quantity
  end

  def update_booked_slots(time)
    working_time_slots.by_date(time).each(&:rebuild_masks)
  end

  def pricing_rule
    record = AvailabilitySearchService::PRICING_BY_BOOKING_MODE[booking_mode]
    return {mode: :quantity} unless record

    unit_name =  ListingViewUtils.translate_unit(unit_type, unit_tr_key) rescue nil
    record[unit_name.to_s] || {mode: :quantity}
  end

  def calculate_tx_quantity(tx_params)
    quantity = tx_params[:quantity] || 1
    rule = self.pricing_rule
    if rule[:mode] == :quantity || !booking?
      quantity
    else
      duration =
        if booking_per_day_or_night?
          DateUtils.duration(tx_params[:start_on], tx_params[:end_on])
        else
          DateUtils.duration_in_hours(tx_params[:start_time], tx_params[:end_time])
        end

      (duration.to_f / rule[:factor]).ceil
    end
  end

  def calculate_tx_duration(tx_params)
    if tx_params[:per_hour] || tx_params[:start_on]
      if tx_params[:per_hour]
        DateUtils.duration_in_hours(tx_params[:start_time], tx_params[:end_time])
      else
        DateUtils.duration(tx_params[:start_on], tx_params[:end_on])
      end
    else
      tx_params[:quantity] || 1
    end
  end

  def auto_time_zone
    tz_name =
      if origin_loc && origin_loc.latitude && origin_loc.longitude
        TZWhere.lookup(origin_loc.latitude, origin_loc.longitude)
      else
        'UTC'
      end
    ActiveSupport::TimeZone[tz_name]
  end

  def friendly_tz_name
    tz = auto_time_zone.tzinfo
    cp = tz.current_period
    offset = cp.utc_total_offset
    format("%s %s%02d:%02d", cp.abbreviation, (offset < 0 ? "-" : "+"),  offset.abs / 3600, offset.abs % 3600 / 60)
  end

  def self.semi_premium_pricing?(listing)
    listing = Listing.find(listing.id)
    author = Person.find(listing.author.id)
    listing.price && author.is_affiliate? && listing.affiliate_pricing?
  end

  def deep_clone
    Listing.transaction do
      new_record = self.dup
      new_record.uuid = nil
      new_record.save!

      # images
      listing_images.each do |li|
        new_li = li.dup
        new_li.listing_id = new_record.id
        new_li.image = li.image
        new_li.save(validate: false)
      end

      # location
      new_record.origin_loc = origin_loc.dup
      new_record.save(validate: false)

      # custom fields
      custom_field_values.each do |cfv|
        new_cfv = cfv.dup
        new_cfv.listing_id = new_record.id
        new_cfv.save(validate: false)
        CustomFieldOptionSelection.where(listing_id: self.id, custom_field_value_id: cfv.id).each do |cfos|
          new_cfos = cfos.dup
          new_cfos.listing_id = new_record.id
          new_cfos.custom_field_value_id = new_cfv.id
          new_cfos.save(validate: false)
        end
      end

      # time slots
      working_time_slots.each do |slot|
        new_slot = slot.dup
        new_slot.listing = new_record
        new_slot.save
      end

      new_record
    end
  end

  def capacity
    read_attribute(:capacity).to_i
  end

  def has_fareharbor_booking_url?
    ext_booking_url.present? && ext_booking_url =~ /https:\/\/fareharbor\.com\/embeds/
  end

  def has_rezdy_booking_url?
    ext_booking_url.present? && ext_booking_url =~ /\.rezdy\.com\//
  end

  def has_memberdeals_booking_url?
    ext_booking_url.present? && ext_booking_url =~ /https:\/\/memberdeals\.com\//
  end

  def adjusted_fareharbor_booking_url(user_id)
    url = URI.parse(ext_booking_url.strip)
    params = Rack::Utils.parse_query(url.query)
    params["ref"] = user_id
    params['asn-ref'] = "ownoutdoors"
    url.query = params.to_param
    url.to_s
  end

  # listing custom field 'Rating'
  def set_admin_rating
    rating = 100
    if custom_dropdown_field_value = custom_dropdown_field_values.includes(:selected_options).where(custom_field_id: 34307).first
      if custom_field_option = custom_dropdown_field_value.selected_options.first
        case custom_field_option.title
        when 'Excellent'
          rating = 10
        when 'Good'
          rating = 20
        when 'N/A'
          rating = 30
        else
          rating = 40
        end
      end
    end
    self.admin_rating = rating
  end

  def hide_from=(data)
    usernames = data.first.split(',')
    self.hide_from_person_ids = Person.where(username: usernames).map(&:id)
  end

  def hide_from
    hide_from_people.map(&:username).join(',') + ','
  end

  def show_for=(data)
    usernames = data.first.split(',')
    self.show_for_person_ids = Person.where(username: usernames).map(&:id)
  end

  def show_for
    show_for_people.map(&:username).join(',') + ','
  end

  #listing_index
  def custom_text_fields
    custom_field_values.map(&:text_value).join(' ')
  end

  #listing_index
  def author_name
    author && [author.given_name, author.family_name, author.display_name].join(' ')
  end

  def deg_to_rad(degrees)
    degrees && degrees * Math::PI / 180
  end

  #listing_index
  def latitude_rad
    deg_to_rad(origin_loc&.latitude)
  end

  #listing_index
  def longitude_rad
    deg_to_rad(origin_loc&.longitude)
  end

  #listing_index
  def custom_dropdown_field_options
    custom_dropdown_field_values.map do |value|
      value.selected_options.map(&:id)
    end.flatten
  end

  #listing_index
  def custom_checkbox_field_options
    custom_checkbox_field_values.map do |value|
      value.selected_options.map(&:id)
    end.flatten
  end

  def ajusted_listing_show_for_person_ids
    count = listing_show_for_people.size
    if count > 0
      listing_show_for_person_ids
    else
      [0]
    end
  end

  def url
    "#{id}-#{title.to_url}"
  end

  def free?
    price_cents == 0
  end

  def tax_percent
    taxes.first&.percent
  end

  def service_fee_percent
    service_fees.first&.percent
  end

  private

  def reject_blank_tax_or_service_fee(attributes)
    # Reject if both title and percent are blank or only whitespace
    title_blank = attributes['title'].blank?
    percent_blank = attributes['percent'].blank?
    
    reject = title_blank && percent_blank
    Rails.logger.debug "Rejecting tax/service fee attributes: #{attributes.inspect} -> #{reject}"
    reject
  end
end

