# == Schema Information
#
# Table name: documents
#
#  id                    :integer          not null, primary key
#  title                 :string(255)
#  listing_id            :integer
#  transaction_id        :integer
#  person_id             :string(22)
#  person_role           :string(255)
#  document_role         :string(255)
#  doc_type              :string(255)
#  docusign_id           :string(255)
#  document_file_name    :string(255)
#  document_content_type :string(255)
#  document_file_size    :integer
#  document_updated_at   :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  community_id          :integer
#

class Document < ApplicationRecord
  PERSON_ROLES = ['admin', 'lender', 'renter']

  DOCUMENT_ROLES = ['template', 'request', 'signed']

  DOC_TYPES = ['rental', 'waiver']

  belongs_to :community
  belongs_to :person
  belongs_to :listing
  belongs_to :tx, class_name: 'Transaction', foreign_key: :transaction_id

  scope :rentals, -> { where(doc_type: 'rental') }
  scope :waivers, -> { where(doc_type: 'waiver') }

  scope :templates, -> { where(document_role: 'template') }
  scope :requests, -> { where(document_role: 'request') }
  scope :signed, -> { where(document_role: 'signed') }

  scope :shared_templates, -> { templates.where(person_role: 'admin') }

  scope :by_community, ->(community_id) { where(community_id: community_id) }
  scope :by_author, ->(author_id) { where(person_id: author_id) }

  scope :ordered, -> { order('created_at DESC') }

  has_attached_file :document
  validates_attachment_size :document, :less_than => 20 * 1024 * 1024
  validates_attachment_content_type :document, :unless => Proc.new {|model| model.document.nil? },
    :content_type =>  ["application/pdf","application/vnd.ms-excel",
             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
             "application/msword",
             "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
             "image/jpeg", "image/png", "image/gif", "image/pjpeg", "image/x-png"]

  FIELDS = [
    'current_year', 'current_month', 'current_day',
    'listing_title', 'listing_rules',
    'seller_name', 'seller_address',
    'buyer_name', 'buyer_address',
  ]

  def download_from_docusign
    auth = DocusignAuthorization.where(community_id: community_id).first
    return unless auth && auth.authorized? && docusign_id.present?
    api_client = auth.api_client
    templates_api = DocuSign_eSign::TemplatesApi.new(api_client)
    env_template = templates_api.get(APP_CONFIG.docusign_account_id, docusign_id)
    t_document = env_template.documents.first
    filename = t_document.name
    basename = File.basename(t_document.name).gsub(/[^-_a-zA-Z0-9.]/, '_')
    extname = File.extname(t_document.name)
    temp_name = File.join(Rails.root, "tmp", basename+extname)
    temp_document = templates_api.get_document(APP_CONFIG.docusign_account_id, t_document.document_id, docusign_id)
    FileUtils.cp(temp_document.path, temp_name)
    self.document = File.open(temp_name)
    save
    temp_document.delete
  end

  def title_or_name
    [title, document_file_name].find(&:present?)
  end

  def title_with_type
    doc_type = docusign_id.present? ? "DocuSign" : "Custom"
    format "%s (%s)", title_or_name, doc_type
  end

  def has_listings?
    Listing.where(document_id: self.id).exists?
  end
end
