# == Schema Information
#
# Table name: person_white_labels
#
#  id                     :bigint           not null, primary key
#  person_id              :string(255)
#  logo_file_name         :string(255)
#  logo_content_type      :string(255)
#  logo_file_size         :integer
#  logo_updated_at        :datetime
#  logo_processing        :boolean
#  wide_logo_file_name    :string(255)
#  wide_logo_content_type :string(255)
#  wide_logo_file_size    :integer
#  wide_logo_updated_at   :datetime
#  wide_logo_processing   :boolean
#  custom_color1          :string(255)
#  custom_color2          :string(255)
#  slogan_color           :string(255)
#  description_color      :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  domain                 :string(255)
#  favicon_file_name      :string(255)
#  favicon_content_type   :string(255)
#  favicon_file_size      :integer
#  favicon_processing     :boolean
#  email_sender           :string(255)
#  design                 :string(255)
#  email_public           :boolean          default(FALSE)
#
# Indexes
#
#  index_person_white_labels_on_person_id  (person_id)
#

class PersonWhiteLabel < ApplicationRecord
  belongs_to :person

  has_attached_file :logo,
                    :styles => {
                      :header => "192x192#",
                      :header_icon => "40x40#",
                      :header_icon_highres => "80x80#",
                      :apple_touch => "152x152#",
                      :original => "600x600>"
                    },
                    :convert_options => {
                      # iOS makes logo background black if there's an alpha channel
                      # And the options has to be in correct order! First background, then flatten. Otherwise it will
                      # not work.
                      :apple_touch => "-background white -flatten"
                    },
                    :keep_old_files => true

  validates_attachment_content_type :logo,
                                    :content_type => ["image/jpeg",
                                                      "image/png",
                                                      "image/gif",
                                                      "image/pjpeg",
                                                      "image/x-png"]

  has_attached_file :wide_logo,
                    :styles => {
                      :header => "168x40#",
                      :paypal => "190x60>", # This logo is shown in PayPal checkout page. It has to be 190x60 according to PayPal docs.
                      :header_highres => "336x80#",
                      :original => "600x600>"
                    },
                    :convert_options => {
                      # The size for paypal logo will be exactly 190x60. No cropping, instead the canvas is extended with white background
                      :paypal => "-background white -gravity center -extent 190x60"
                    },
                    :keep_old_files => true

  validates_attachment_content_type :wide_logo,
                                    :content_type => ["image/jpeg",
                                                      "image/png",
                                                      "image/gif",
                                                      "image/pjpeg",
                                                      "image/x-png"]

  has_attached_file :favicon,
                    :styles => {
                      :favicon => "32x32#"
                    },
                    :default_style => :favicon,
                    :convert_options => {
                      :favicon => "-depth 32 -strip",
                    },
                    :default_url => ->(_) { ActionController::Base.helpers.asset_path("favicon.ico") }

  validates_attachment_content_type :favicon,
                                    :content_type => ["image/jpeg",
                                                      "image/png",
                                                      "image/gif",
                                                      "image/x-icon",
                                                      "image/vnd.microsoft.icon"]

  validates :email_sender , length: { maximum: 255 },
    format: { with: /\A[A-Z0-9._%\-\+\~\/]+@([A-Z0-9-]+\.)+[A-Z]+\z/i, message: :must_be_valid_email },
    if: -> { email_sender.present? }

  process_in_background :logo
  process_in_background :wide_logo
  process_in_background :favicon

  def show
    {
      color1: custom_color1 ? "##{custom_color1}" : "#4a90e2",
      color2: custom_color2 ? "##{custom_color2}" : "#2ab865",
      slogancolor: slogan_color ? "##{slogan_color}" : "#ffffff",
      descriptioncolor: description_color ? "##{description_color}" : "#ffffff",
      design: design,
      image_map: {
        cover_photo:         nil,
        small_cover_photo:   nil,
        wide_logo_lowres:    wide_logo.url(:header),
        wide_logo_highres:   wide_logo.url(:header_highres),
        square_logo_lowres:  logo.url(:header_icon),
        square_logo_highres: logo.url(:header_icon_highres),
      },
      no_top_search: ladera_enabled?,
    }
  end

  def full_name
    PersonViewUtils.person_display_names_for_type(person, nil).first
  end

  def full_domain
    default_host, default_port = APP_CONFIG.domain.split(':')
    dom = domain
    dom += ":#{default_port}" unless default_port.blank?
    dom
  end

  def ladera_enabled?
    design == 'ladera'
  end

  def self.ladera_users
    where(design: 'ladera')
  end

  def self.enable_ladera_for_user(person_id)
    person = Person.find(person_id)
    white_label = person.person_white_label || person.build_person_white_label
    white_label.update(design: 'ladera')
  end

  def self.disable_ladera_for_user(person_id)
    person = Person.find(person_id)
    white_label = person.person_white_label
    white_label&.update(design: nil)
  end
end
