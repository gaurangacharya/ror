# == Schema Information
#
# Table name: people
#
#  id                                 :string(22)       not null, primary key
#  uuid                               :binary(16)       not null
#  community_id                       :integer          not null
#  created_at                         :datetime
#  updated_at                         :datetime
#  is_admin                           :integer          default(0)
#  locale                             :string(255)      default("fi")
#  preferences                        :text(65535)
#  active_days_count                  :integer          default(0)
#  last_page_load_date                :datetime
#  test_group_number                  :integer          default(1)
#  username                           :string(255)      not null
#  email                              :string(255)
#  encrypted_password                 :string(255)      default(""), not null
#  legacy_encrypted_password          :string(255)
#  reset_password_token               :string(255)
#  reset_password_sent_at             :datetime
#  remember_created_at                :datetime
#  sign_in_count                      :integer          default(0)
#  current_sign_in_at                 :datetime
#  last_sign_in_at                    :datetime
#  current_sign_in_ip                 :string(255)
#  last_sign_in_ip                    :string(255)
#  password_salt                      :string(255)
#  given_name                         :string(255)
#  family_name                        :string(255)
#  display_name                       :string(255)
#  phone_number                       :string(255)
#  description                        :text(65535)
#  image_file_name                    :string(255)
#  image_content_type                 :string(255)
#  image_file_size                    :integer
#  image_updated_at                   :datetime
#  image_processing                   :boolean
#  facebook_id                        :string(255)
#  authentication_token               :string(255)
#  community_updates_last_sent_at     :datetime
#  min_days_between_community_updates :integer          default(1)
#  deleted                            :boolean          default(FALSE)
#  cloned_from                        :string(22)
#  rating_average                     :float(24)        default(0.0)
#  rating_count                       :integer          default(0)
#  is_confirmed                       :integer          default(0)
#  guest                              :boolean          default(FALSE)
#  is_vendor                          :boolean          default(FALSE)
#  sort_priority                      :integer          default(3)
#  website_url                        :string(255)
#  membership_status                  :integer          default("free"), not null
#  membership_expires_at              :date
#  referral_id                        :string(255)
#  referrer_id                        :string(255)
#  signup_charge_id                   :string(255)
#  is_affiliate                       :boolean          default(FALSE)
#  is_hotel                           :boolean          default(FALSE)
#  notes                              :string(255)
#  hotel_id                           :string(255)
#  booking_start                      :string(255)
#  booking_end                        :string(255)
#  booking_date                       :string(255)
#  referral_address                   :string(255)
#  tripadvisor_location_id            :string(255)
#  chargebee_id                       :string(255)
#  event_last_modified_at             :datetime
#  chargebee_data                     :text(65535)
#  chargebee_hosted_page_id           :string(255)
#  cb_item_id                         :bigint
#  signup_plan_id                     :bigint
#  customer_message_under_book        :string(255)
#  pdf_file_name                      :string(255)
#  pdf_content_type                   :string(255)
#  pdf_file_size                      :integer
#  pdf_updated_at                     :datetime
#  embed_document                     :string(1024)
#  embed_document_button_color        :string(255)
#  fareharbor                         :boolean          default(FALSE)
#  person_white_label_id              :bigint
#  name_on_reservation                :string(255)
#  reviews_disabled                   :boolean          default(FALSE)
#  hotel_guest                        :boolean          default(FALSE)
#
# Indexes
#
#  index_people_on_authentication_token          (authentication_token)
#  index_people_on_cb_item_id                    (cb_item_id)
#  index_people_on_community_id                  (community_id)
#  index_people_on_email                         (email) UNIQUE
#  index_people_on_facebook_id                   (facebook_id)
#  index_people_on_facebook_id_and_community_id  (facebook_id,community_id) UNIQUE
#  index_people_on_id                            (id)
#  index_people_on_person_white_label_id         (person_white_label_id)
#  index_people_on_reset_password_token          (reset_password_token) UNIQUE
#  index_people_on_signup_plan_id                (signup_plan_id)
#  index_people_on_username                      (username)
#  index_people_on_username_and_community_id     (username,community_id) UNIQUE
#  index_people_on_uuid                          (uuid) UNIQUE
#

require 'json'
require 'rest_client'
require "open-uri"

# This class represents a person (a user of Sharetribe).

class Person < ApplicationRecord
  include ChargebeeRails::Customer
  include RansackSearchable

  has_attached_file :pdf, processors: [:to_image], styles: {original: { format: :png } }, validate_media_type: false
  validates_attachment :pdf, content_type: { content_type: ['application/pdf', 'application/x-pdf', "image/jpeg", "image/png", "image/pjpeg", "image/x-png"] }

  # Added by ChargebeeRails.
  has_one :subscription, :dependent => :destroy
  serialize :chargebee_data, JSON

  include ErrorsHelper
  include ApplicationHelper

  self.primary_key = "id"

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :omniauthable

  attr_accessor :guid, :password2, :form_login, :form_given_name, :form_family_name, :form_password, :form_password2, :form_email, :consent, :input_again, :send_notifications, :delete_pdf, :skip_phone_validation

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  has_many :listings, -> { where(deleted: 0) }, :dependent => :destroy, :foreign_key => "author_id"
  has_many :emails, :dependent => :destroy, :inverse_of => :person

  has_one :location, -> { where(location_type: :person) }, :dependent => :destroy
  has_one :referral_location, class_name: 'Location', foreign_key: 'referral_id'

  has_many :participations, :dependent => :destroy
  has_many :conversations, :through => :participations, :dependent => :destroy
  has_many :authored_testimonials, :class_name => "Testimonial", :foreign_key => "author_id", :dependent => :destroy
  has_many :received_testimonials, -> { order("id DESC")}, :class_name => "Testimonial", :foreign_key => "receiver_id", :dependent => :destroy
  has_many :messages, :foreign_key => "sender_id"
  has_many :authored_comments, :class_name => "Comment", :foreign_key => "author_id", :dependent => :destroy
  belongs_to :community
  has_many :community_memberships, :dependent => :destroy
  has_many :communities, -> { where("community_memberships.status = 'accepted'") }, :through => :community_memberships
  has_one  :community_membership, :dependent => :destroy
  has_one  :accepted_community, -> { where("community_memberships.status= 'accepted'") }, through: :community_membership, source: :community
  has_many :invitations, :foreign_key => "inviter_id", :dependent => :destroy
  has_many :auth_tokens, :dependent => :destroy
  has_many :follower_relationships
  has_many :followers, :through => :follower_relationships, :foreign_key => "person_id"
  has_many :inverse_follower_relationships, :class_name => "FollowerRelationship", :foreign_key => "follower_id"
  has_many :followed_people, :through => :inverse_follower_relationships, :source => "person"
  belongs_to :hotel, :class_name => 'Person', :foreign_key => 'hotel_id'
  belongs_to :cb_item
  belongs_to :signup_plan

  has_and_belongs_to_many :followed_listings, :class_name => "Listing", :join_table => "listing_followers"
  has_one  :person_white_label, :dependent => :destroy
  has_many :person_fareharbors, -> { latest.limit(10) }, :dependent => :destroy
  has_one :fareharbor_company
  has_one :paypal_soap_account, :dependent => :destroy

  accepts_nested_attributes_for :person_white_label, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :emails, reject_if: :all_blank, allow_destroy: true

  scope :chargebee_first_time, ->{ where.not(chargebee_hosted_page_id: nil).where(chargebee_id: nil) }
  scope :chargebee, ->{ where.not(chargebee_id: nil) }
  scope :fareharbor, ->{ where(fareharbor: true) }

  deprecate communities: "Use accepted_community instead.",
            community_memberships: "Use community_membership instead.",
            deprecator: MethodDeprecator.new

  after_initialize :add_uuid
  before_save :set_sort_priority
  before_save :set_referral_id
  after_save :reindex_listings

  before_validation { pdf.clear if delete_pdf == '1' }

  def to_param
    username
  end

  DEFAULT_TIME_FOR_COMMUNITY_UPDATES = 7.days

  # These are the email notifications, excluding newsletters settings
  EMAIL_NOTIFICATION_TYPES = [
    "email_about_new_messages",
    "email_about_new_comments_to_own_listing",
    "email_when_conversation_accepted",
    "email_when_conversation_rejected",
    "email_about_new_received_testimonials",
    "email_about_confirm_reminders",
    "email_about_testimonial_reminders",
    "email_about_completed_transactions",
    "email_about_new_payments",
    "email_about_new_listings_by_followed_people"

    # These should not yet be shown in UI, although they might be stored in DB
    # "email_when_new_friend_request",
    # "email_when_new_feedback_on_transaction",
    # "email_when_new_listing_from_friend"
  ]
  EMAIL_NEWSLETTER_TYPES = [
    "email_from_admins"
  ]

  serialize :preferences

  validates_length_of :phone_number, :maximum => 25, :allow_nil => true, :allow_blank => true
  validates_length_of :username, :within => 3..100
  validates_length_of :given_name, :within => 1..255, :allow_nil => true, :allow_blank => true
  validates_length_of :family_name, :within => 1..255, :allow_nil => true, :allow_blank => true
  validates_length_of :display_name, :within => 1..60, :allow_nil => true, :allow_blank => true

  validates_presence_of :phone_number, unless: :skip_phone_validation, on: :create

  validates_format_of :username,
                       :with => /\A[A-Z0-9_\-]*\z/i

  USERNAME_BLACKLIST = YAML.load_file("#{Rails.root}/config/username_blacklist.yml")

  validates :username, exclusion: USERNAME_BLACKLIST, uniqueness: {scope: :community_id}

  has_attached_file :image, :styles => {
                      :medium => "288x288#",
                      :small => "108x108#",
                      :thumb => "48x48#",
                      :original => "600x800>"}

  process_in_background :image

  #validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 9.megabytes
  validates_attachment_content_type :image,
                                    :content_type => ["image/jpeg", "image/png", "image/gif",
                                                      "image/pjpeg", "image/x-png"] #the two last types are sent by IE.

  before_validation(:on => :create) do
    self.id = SecureRandom.urlsafe_base64
    set_default_preferences unless self.preferences
  end

  before_validation do
    self.website_url = self.website_url.present? && self.website_url !~ /^http/ ? "http://"+self.website_url : self.website_url
  end

  # same as in kassi.js
  URL_REGEXP = /\A(?:(?:https?):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]-*)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:[\/?#]\S*)?\z/i

  validates_format_of :website_url, with: URL_REGEXP, if: :is_vendor
  validate :website_really_exists



  MEMBERSHIP_STATUSES = {
    MEMBERSHIP_FREE = :free => 0,
    # MEMBERSHIP_STANDARD = :standard => 1,
    MEMBERSHIP_PREMIUM = :premium => 2
  }

  enum membership_status: MEMBERSHIP_STATUSES

  def add_uuid
    self.uuid ||= UUIDUtils.create_raw
  end

  def uuid_object
    if self[:uuid].nil?
      nil
    else
      UUIDUtils.parse_raw(self[:uuid])
    end
  end

  # Creates a new email
  def email_attributes=(attributes)
    ActiveSupport::Deprecation.warn(
      ["Person.email_attributes is deprecated.",
       "Instead of using nested attributes, build each associated",
       "model individually inside a DB transaction in the controller."].join(" "))

    emails.build(attributes)
  end

  def set_emails_that_receive_notifications(email_ids)
    if email_ids
      emails.each do |email|
        email.update_attribute(:send_notifications, email_ids.include?(email.id.to_s))
      end
    end
  end

  def last_community_updates_at
    community_updates_last_sent_at || DEFAULT_TIME_FOR_COMMUNITY_UPDATES.ago
  end

  def self.username_blacklist
    USERNAME_BLACKLIST
  end

  def self.username_available?(username, community_id)
    !USERNAME_BLACKLIST.include?(username.downcase) &&
      !Person
        .where("username = :username AND (is_admin = '1' OR community_id = :cid)", username: username, cid: community_id)
        .present?
  end

  def name_or_username(community_or_display_type=nil)
    display_type = if community_or_display_type.present? && community_or_display_type.instance_of?(Community)
      community_or_display_type.name_display_type
    else
      community_or_display_type
                   end
    if given_name.present?
      if display_type
        case display_type
        when "first_name_with_initial"
          return first_name_with_initial
        when "first_name_only"
          return given_name
        else
          return full_name
        end
      else
        return first_name_with_initial
      end
    else
      return username
    end
  end
  deprecate name_or_username: "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils.",
            deprecator: MethodDeprecator.new

  def full_name
    "#{given_name} #{family_name}"
  end
  deprecate full_name: "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils.",
            deprecator: MethodDeprecator.new

  def first_name_with_initial
    initial = if family_name
      family_name[0,1]
    else
      ""
              end
    "#{given_name} #{initial}"
  end
  deprecate first_name_with_initial: "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils.",
            deprecator: MethodDeprecator.new

  def name(community_or_display_type)
    deprecation_message = "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils."
    MethodDeprecator.new.deprecation_warning(:name, deprecation_message)
    return name_or_username(community_or_display_type)
  end
  # FIXME deprecate on Person#name breaks error reporting
  # deprecate name: "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils.",
  #          deprecator: MethodDeprecator.new

  def given_name_or_username
    if given_name.present?
      return given_name
    else
      return username
    end
  end
  deprecate given_name_or_username: "This is view logic (how to display name) and thus should not be in model layer. Consider using PersonViewUtils.",
            deprecator: MethodDeprecator.new

  def long_name
    "#{username} (#{emails.first&.address}) #{display_name}"
  end

  def set_given_name(name)
    update({:given_name => name })
  end

  def street_address
    if location
      return location.address
    else
      return nil
    end
  end

  def update(params)
    if params[:preferences]
      super(params)
    else

      #Handle location information
      if params[:location]
        if self.location && self.location.address != params[:street_address]
          #delete location and create a new one
          self.location.delete
        end

        # Set the address part of the location to be similar to what the user wrote.
        # the google_address field will store the longer string for the exact position.
        params[:location][:address] = params[:street_address] if params[:street_address]

        self.location = Location.new(params[:location])
        params[:location].each {|key| params[:location].delete(key)}
        params.delete(:location)
      end

      if params[:referral_address].present?
        # Check if address changed by comparing the address field, not the object
        address_changed = self.referral_location.nil? || self.referral_location.address != params[:referral_address]
        
        if address_changed
          self.referral_location ||= Location.new(location_type: 'referral', referral_id: self.id)
          self.referral_location.address = params[:referral_address]
          
          # Attempt geocoding - check if it succeeds
          geocoding_success = self.referral_location.search_and_fill_latlng(params[:referral_address])
          
          if geocoding_success
            self.referral_location.save
          else
            # Log warning but still save the location with address (coordinates will be nil)
            Rails.logger.warn("Geocoding failed for referral_address: #{params[:referral_address]} for person: #{self.username}")
        self.referral_location.save
          end
        end
      end

      save
      super(params.except("password2", "street_address"))
    end
  end

  def picture_from_url(url)
    self.image = URI.open(url)
    self.save
  end

  def store_picture_from_facebook!
    if self.facebook_id
      resp = RestClient.get(
        "http://graph.facebook.com/#{FacebookSdkVersion::SERVER}/#{self.facebook_id}/picture?type=large&redirect=false")
      url = JSON.parse(resp)["data"]["url"]
      self.picture_from_url(url)
    end
  end

  def offers
    listings.offers
  end

  def requests
    listings.requests
  end

  def set_default_preferences
    self.preferences = {}
    EMAIL_NOTIFICATION_TYPES.each { |t| self.preferences[t] = true }
    EMAIL_NEWSLETTER_TYPES.each { |t| self.preferences[t] = true }
    self.min_days_between_community_updates = 100_000
    save
  end

  def password2
    if new_record?
      return form_password2 || ""
    end
  end

  def can_delete_email(email)
    EmailService.can_delete_email(self.emails,
                                  email,
                                  self.community.allowed_emails)[:result]
  end

  # Returns true if the person has global admin rights in Sharetribe.
  def is_admin?
    is_admin == 1
  end

  # Starts following a listing
  def follow(listing)
    followed_listings << listing
  end

  # Unfollows a listing
  def unfollow(listing)
    followed_listings.delete(listing)
  end

  # Checks if this user is following the given listing
  def is_following?(listing)
    followed_listings.include?(listing)
  end

  # Updates the user following status based on the given status
  # for the given listing
  def update_follow_status(listing, status)
    unless id == listing.author.id
      if status
        follow(listing) unless is_following?(listing)
      else
        unfollow(listing) if is_following?(listing)
      end
    end
  end

  def read(conversation)
    conversation.participations.where(["person_id LIKE ?", self.id]).first.update_attribute(:is_read, true)
  end

  def consent
    community_membership.consent
  end

  def is_marketplace_admin?(community)
    community_membership.community_id == community.id && community_membership.admin?
  end

  def has_admin_rights?(community)
    is_admin? || is_marketplace_admin?(community)
  end

  def should_receive?(email_type)
    confirmed_email = !confirmed_notification_emails.empty?
    if email_type == "community_updates"
      # this is handled outside prefenrences so answer separately
      return confirmed_email && min_days_between_community_updates < 100000
    end

    confirmed_email && preferences && preferences[email_type]
  end

  def profile_info_empty?
    (phone_number.nil? || phone_number.blank?) && (description.nil? || description.blank?) && location.nil?
  end

  def member_of?(community)
    community.members.include?(self)
  end

  def banned?
    community_membership.banned?
  end

  def has_email?(address)
    Email.find_by_address_and_person_id(address, self.id).present?
  end

  def confirmed_notification_emails
    emails.select do |email|
      email.send_notifications && email.confirmed_at.present?
    end
  end

  def confirmed_notification_email_addresses
    self.confirmed_notification_emails.collect(&:address)
  end

  # Notice: If no confirmed notification emails is found, this
  # method returns the first confirmed emails
  def confirmed_notification_emails_to
    if guest?
      primary_email.address
    else
      send_message_to = EmailService.emails_to_send_message(emails)
      EmailService.emails_to_smtp_addresses(send_message_to)
    end
  end

  # Primary email is the first email address that is
  #
  # - confirmed
  # - notifications allowed
  #
  # Returns Email record
  #
  def primary_email
    if guest?
      Email.new(address: email.to_s.split("/", 2).last)
    else
      EmailService.emails_to_send_message(emails).first
    end
  end

  # Notice: If no confirmed notification emails is found, this
  # method returns the first confirmed emails
  def confirmed_notification_email_to
    send_message_to = EmailService.emails_to_send_message(emails).first

    Maybe(send_message_to).map { |email|
      EmailService.emails_to_smtp_addresses([email])
    }.or_else(nil)
  end

  # Returns true if the address given as a parameter is confirmed
  def has_confirmed_email?(address)
    email = Email.find_by_address_and_person_id(address, self.id)
    email.present? && email.confirmed_at.present?
  end

  def has_valid_email_for_community?(community)
    community.can_accept_user_based_on_email?(self)
  end

  def update_facebook_data(facebook_id)
    self.update_attribute(:facebook_id, facebook_id)
    if self.image_file_size.nil?
      begin
        self.store_picture_from_facebook!
      rescue StandardError => e
        # We can just catch and log the error, because if the profile picture upload fails
        # we still want to make the user creation pass, just without the profile picture,
        # which user can upload later
        logger.error(e.message, :facebook_existing_user_profile_picture_upload_failed, { person_id: self.id })
      end
    end
  end

  def self.find_by_email_address_and_community_id(email_address, community_id)
    Maybe(
      Email.find_by_address_and_community_id(email_address, community_id)
    ).person.or_else(nil)
  end

  def reset_password_token_if_needed
    # Devise 3.1.0 doesn't expose methods to generate reset_password_token without
    # sending the email, so this code is copy-pasted from Recoverable module
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    save(:validate => false)
    raw
  end

  # If image_file_name is null, it means the user
  # does not have a profile picture.
  def has_profile_picture?
    image_file_name.present?
  end

  # Tell Devise that email is not required
  def email_required?
    false
  end

  # Tell Devise that email is not required
  def email_changed?
    false
  end

  # A person inherits some default settings from the community in which she is joining
  def inherit_settings_from(current_community)
    self.min_days_between_community_updates = current_community.default_min_days_between_community_updates
  end

  def should_receive_community_updates_now?
    return false unless should_receive?("community_updates")
    # return whether or not enought time has passed. The - 45.minutes is because the sending takes some time so we want
    # 1 day limit to match even if there's 23.55 minutes passed since last sending.
    return true if community_updates_last_sent_at.nil?

    return community_updates_last_sent_at + min_days_between_community_updates.days - 45.minutes < Time.now
  end

  # Returns and email that is pending confirmation
  # If community is given as parameter, in case of many pending
  # emails the one required by the community is returned
  def latest_pending_email_address(community=nil)
    pending_emails = Email.where(:person_id => id, :confirmed_at => nil).pluck(:address)

    allowed_emails = if community && community.allowed_emails
      pending_emails.select do |e|
        community.email_allowed?(e)
      end
    else
      pending_emails
    end

    allowed_emails.last
  end

  def follows?(person)
    followed_people_by_id.include?(person.id)
  end

  def followed_people_by_id
    @followed_people_by_id ||= followed_people.group_by(&:id)
  end

  def self.members_of(community)
    joins(:communities).where("communities.id" => community.id)
  end


  # Overrides method injected from Devise::DatabaseAuthenticatable
  # Updates password with password that has been rehashed with new algorithm.
  # Removes legacy password and salt.
  def valid_password?(password)
    if self.legacy_encrypted_password.present?
      if digest(password, self.password_salt).casecmp(self.legacy_encrypted_password) == 0
        self.password = password
        self.legacy_encrypted_password = nil
        self.password_salt = nil
        self.save!
        true
      else
        false
      end
    else
      super
    end
  end

  # Overrides method injected from Devise::DatabaseAuthenticatable
  # Removes legacy pashsword and salt.
  def password=(*args)
    self.legacy_encrypted_password = nil
    self.password_salt = nil
    super
  end

  def rebuild_rating
    self.rating_average = received_testimonials.average(:grade).to_f
    self.rating_count = received_testimonials.count
    save
  end

  def self.build_guest(community)
    guest = Person.new
    guest.id = SecureRandom.urlsafe_base64
    guest.username = SecureRandom.urlsafe_base64
    guest.given_name = 'Guest'
    guest.family_name = 'Guest'
    guest.community = community
    guest.guest = true
    guest.community_membership = CommunityMembership.new(person: guest, community: community)
    guest.skip_phone_validation = true
    guest
  end

  def store_guest_info(params, community = nil)
    username = Devise.friendly_token[0,20].tr('-','X')
    self.given_name = params[:user][:first_name]
    self.family_name = params[:user][:last_name]
    self.display_name = [params[:user][:first_name], params[:user][:last_name]].join(" ")
    self.email = username + "/" + params[:user][:email]
    self.username = username
    self.locale = I18n.locale
    self.password = Devise.friendly_token[0,20].tr('-','X')
    self.phone_number = params[:user][:phone]
    self.consent = community.consent
    self.notes = params[:user][:notes]
    self.booking_start = params[:user][:booking_start]
    self.booking_end = params[:user][:booking_end]
    self.name_on_reservation = params[:user][:name_on_reservation]
    self.hotel_guest = params[:user][:hotel_guest]
    self.save!
    self
  end

  def reset_password(new_password, new_password_confirmation)
    if new_password.present?
      self.password = new_password
      self.password_confirmation = new_password_confirmation
      save(validate: false)
    else
      errors.add(:password, :blank)
      false
    end
  end

  def premium_active?
    premium_member? && membership_status && premium_valid_date?
  end

  def premium_deactivated?
    premium_member? && !premium_active?
  end

  def premium_member?
    signup_charge_id.present?
  end

  def premium_valid_date?
    membership_expires_at && Date.today <= membership_expires_at
  end

  def premium_pricing?(listing)
    premium_or_admin_active? && semi_premium_pricing?(listing)
  end

  def semi_premium_pricing?(listing)
    Listing.semi_premium_pricing?(listing)
  end

  def premium_or_admin_active?
    has_admin_rights?(community) || (is_affiliate? && !is_hotel?) || premium_active?
  end

  def hotel_pricing?(listing)
    author = Person.find(listing.author.id)
    is_hotel? && listing.price && author.is_affiliate?
  end

  def toggle_affiliate
    if is_affiliate
      self.is_affiliate = false
    else
      self.referral_id = self.referral_id.presence || generate_referral_id
      self.is_affiliate = true
    end
    save
  end

  def mark_as_member(charge_id, ref_id)
    self.referrer_id = self.referrer_id.presence || ref_id
    self.signup_charge_id = charge_id
    self.referral_id = self.referral_id.presence || generate_referral_id
    self.membership_status = true
    self.membership_expires_at = 1.year.from_now
    save
  end

  def is_hotel_guest?
    guest? && hotel && hotel.is_hotel?
  end

  def booking_string
    if booking_start.present? && booking_end.present?
      ds = Time.parse(booking_start)
      de = Time.parse(booking_end)
      I18n.l(ds, :format => :short_date) + ", " + ds.strftime("%l:%M%P") + " - " + de.strftime("%l:%M%P")
    end
  rescue StandardError => e
  end

  def notice_coupon(community_id, code)
    coupon, can_use = Coupon.can_use?(community_id, code)
    if can_use
      CouponUsage.create(coupon_id: coupon.id, person_id: self.id)
    end
  end

  private

  def digest(password, salt)
    str = [password, salt].flatten.compact.join
    ::Digest::SHA256.hexdigest(str)
  end

  def logger
    @logger ||= SharetribeLogger.new(:person, logger_metadata.keys).tap { |logger|
      logger.add_metadata(logger_metadata)
    }
  end

  def logger_metadata
    { person_uuid: uuid }
  end

  def reindex_listings
    if is_confirmed_changed? || is_vendor_changed? || sort_priority_changed? || is_affiliate_changed?
      listings.each do |listing|
        listing.delta = true
        listing.save
      end
    end
  end

  def set_sort_priority

    # 1) The TOP listings: Vendor/Business with their own account that uploaded/changed their RED profile shop) AND/OR
    self.sort_priority = if is_vendor? && is_confirmed? && image_file_name.present? && image_file_name != 'gray_shop_logo.png' && image_file_name != 'red_shop_logo.png'
      1
    # 1) Individual provider that uploaded/changed their GRAY profile pic. This will give them incentive to add a profile pic.
    elsif !is_vendor? && is_confirmed? && image_file_name.present?
      1
    # 2) The MIDDLE: Vendor/Business with their own account WITH RED profile shop pic
    elsif is_vendor? && is_confirmed? && (image_file_name.blank? || image_file_name == 'red_shop_logo.png')
      2
    # 2) AND/OR Individual provider WITHOUT profile pic.
    elsif !is_vendor? && is_confirmed? && image_file_name.blank?
      3
    # 3) LAST: Vendor/Business that Admins created (GRAY profile pics)
    elsif is_vendor? && !is_confirmed? && (image_file_name.blank? || image_file_name == 'gray_shop_logo.png')
      3
    else
      4
                         end
  end

  def website_really_exists
    if (new_record? || website_url_changed?) && website_url.to_s =~ URL_REGEXP
      begin
        domain = URI.parse(website_url).host
        Socket.gethostbyname(domain)
      rescue SocketError
        errors.add(:website_url_no_dns, "Website URL does not exist")
      end
    end
  end

  def set_referral_id
    if new_record? && signup_charge_id.present?
      self.referral_id = generate_referral_id
      if !is_vendor && !is_hotel
        self.membership_status = true
        self.membership_expires_at = 1.year.from_now
      end
    end
  end

  def generate_referral_id
    prefix = is_vendor ? "A" : "M"
    suffix = Date.today.strftime "%y%m"
    while true
      tail = format("%04d", rand(10000))
      ref_id = [prefix, suffix, tail].join("")
      return ref_id unless Person.where(referral_id: ref_id).exists?
    end
  end

end
