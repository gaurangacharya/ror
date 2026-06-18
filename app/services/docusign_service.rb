class DocusignService
  attr_reader :transaction, :listing, :document

  def initialize(tx)
    @transaction = tx
    @listing = tx.listing
    @document = tx.listing.document
  end

  def send_documents!
    return unless listing.use_documents?
    if has_docusign?
      send_docusign
    elsif has_attachment?
      send_attachment
    end
  end

  def has_docusign?
    document && document.docusign_id.present?
  end

  ROLE_OWNER = 'owner'
  ROLE_RENTER = 'renter'
  STATUS_SENT = 'sent'

  # send through docusign flow using docusign pre-created template
  def send_docusign

    if transaction.booking
      date = transaction.booking.start_date_time
      start_on = [
        {tabLabel: "start_on_year", value: date.year.to_s},
        {tabLabel: "start_on_day", value: date.day.to_s},
        {tabLabel: "start_on_month", value: date.strftime("%B")},
      ]
    else
      start_on = []
    end

    if transaction.booking
      date = transaction.booking.end_date_time
      end_on = [
        {tabLabel: "end_on_year", value: date.year.to_s},
        {tabLabel: "end_on_day", value: date.day.to_s},
        {tabLabel: "end_on_month", value: date.strftime("%B")},
      ]
    else
      end_on = []
    end

    date = listing.auto_time_zone.now

    envelope = DocuSign_eSign::EnvelopeDefinition.new({
      emailSubject: "Fill agreement for #{listing.title}",
      status: STATUS_SENT,
      templateId: document.docusign_id,
      templateRoles: [
        {
          roleName: ROLE_RENTER,
          name: transaction.starter.full_name,
          email: transaction.starter.primary_email.address,
          tabs: {
            textTabs: [
              {tabLabel: "renter_address", value: transaction.starter.location&.address.to_s},
              {tabLabel: "renter_name", value: transaction.starter.full_name},
              {tabLabel: "renter_name_1", value: transaction.starter.full_name},
            ]
          }
        },
        {
          roleName: ROLE_OWNER,
          name: listing.author.full_name,
          email: listing.author.primary_email.address,
          tabs: {
            textTabs: [
              {tabLabel: "listing_title", value: listing.title},
              {tabLabel: "listing_address", value: listing.origin_loc&.address},

              {tabLabel: "current_year", value: date.year.to_s},
              {tabLabel: "current_day", value: date.day.to_s},
              {tabLabel: "current_month", value: date.strftime("%B")},
              {tabLabel: "current_month_name", value: date.strftime("%B")},

              {tabLabel: "current_year_1", value: date.year.to_s},
              {tabLabel: "current_day_1", value: date.day.to_s},
              {tabLabel: "current_month_1", value: date.strftime("%B")},
              {tabLabel: "current_month_name_1", value: date.strftime("%B")},

              {tabLabel: "start_date", value: transaction.booking&.start_on.to_s},
              {tabLabel: "end_date", value: transaction.booking&.end_on.to_s},

              {tabLabel: "unit_price", value: transaction.unit_price.to_s},
              {tabLabel: "unit_type", value: transaction.unit_type.to_s},

              {tabLabel: "owner_address", value: listing.author.location&.address},

              {tabLabel: "owner_name", value: listing.author.full_name},
              {tabLabel: "owner_name_1", value: listing.author.full_name},

              {tabLabel: "deposit", value: transaction.deposit.to_s}
            ] + start_on + end_on
          }
        }
      ],
    })

    api_client = DocusignAuthorization.first.api_client
    envelope_api = DocuSign_eSign::EnvelopesApi.new(api_client)
    result = envelope_api.create_envelope(APP_CONFIG.docusign_account_id, envelope)
  end

  def has_attachment?
    document && !has_docusign? && document.document.present?
  end

  # send notification to author 
  def send_attachment
  end
end
