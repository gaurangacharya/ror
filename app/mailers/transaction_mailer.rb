# Transaction mailer
#
# Responsible for:
# - transactions created
# - transaction status changes
# - reminders
#

include ApplicationHelper
include ListingsHelper
include MarkdownHelper

class TransactionMailer < ActionMailer::Base
  include MailUtils

  default :from => APP_CONFIG.sharetribe_mail_from_address
  layout 'email'

  helper EmailTemplateHelper

  def transaction_preauthorized(transaction)
    @transaction = transaction
    @community = transaction.community
    @person_white_label = transaction.person_white_label

    recipient = transaction.author
    set_up_layout_variables(recipient, transaction.community, nil, transaction)
    with_locale(recipient.locale, transaction.community.locales.map(&:to_sym), transaction.community.id) do

      payment_type = transaction.payment_gateway.to_sym
      gateway_expires = MarketplaceService::Transaction::Entity.authorization_expiration_period(payment_type)

      expires = Maybe(transaction).booking.end_on.map { |booking_end|
        MarketplaceService::Transaction::Entity.preauth_expires_at(gateway_expires.days.from_now, booking_end)
      }.or_else(gateway_expires.days.from_now)

      buffer = 1.minute # Add a small buffer (it might take a couple seconds until the email is sent)
      expires_in = TimeUtils.time_to(expires + buffer)

      from = community_specific_sender(@community, transaction)
      premailer_mail(
        mail_params(
          @recipient,
          from,
          t("emails.transaction_preauthorized.subject", requester: PersonViewUtils.person_display_name(transaction.starter, @community), listing_title: transaction.listing.title))) do |format|
        format.html {
          render locals: {
                   payment_expires_in_unit: expires_in[:unit],
                   payment_expires_in_count: expires_in[:count]
                 }
        }
      end
    end
  end

  def transaction_preauthorized_reminder(transaction)
    @transaction = transaction
    @community = transaction.community
    @person_white_label = transaction.person_white_label

    recipient = transaction.author
    set_up_layout_variables(recipient, transaction.community, nil, transaction)
    with_locale(recipient.locale, transaction.community.locales.map(&:to_sym), transaction.community.id) do

      from = community_specific_sender(@community, transaction)
      premailer_mail(
        mail_params(
          @recipient,
          from,
          t("emails.transaction_preauthorized_reminder.subject", requester: transaction.starter.name(@community), listing_title: transaction.listing.title)))
    end
  end

  # seller_model, buyer_model and community can be passed as params for testing purposes
  def payment_receipt_to_seller(transaction, seller_model = nil, buyer_model = nil, community = nil)
    seller_model ||= Person.find(transaction[:listing_author_id])
    buyer_model ||= Person.find(transaction[:starter_id])
    community ||= Community.find(transaction[:community_id])
    transaction_model = Transaction.find(transaction[:id])

    payment_total = transaction[:payment_total]
    service_fee = Maybe(transaction[:charged_commission]).or_else(Money.new(0, payment_total.currency))
    gateway_fee = transaction[:payment_gateway_fee] || Money.new(0, payment_total.currency)
    deposit = transaction[:deposit] && transaction[:deposit] > 0 && transaction[:booking].present? ? transaction[:deposit] : nil

    ar_transaction = ::Transaction.find(transaction[:id])
    @person_white_label = ar_transaction.person_white_label
    prepare_template(community, seller_model, "email_about_new_payments", ar_transaction)
    with_locale(seller_model.locale, community.locales.map(&:to_sym), community.id) do

      you_get = payment_total - service_fee - gateway_fee

      unit_type = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_unit(t[:unit_type], t[:unit_tr_key]) }.or_else(nil)
      quantity_selector_label = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_quantity(t[:unit_type], t[:unit_selector_tr_key]) }.or_else(nil)
      listing_title = if transaction[:booking].try(:[], :per_hour)
        t("emails.new_payment.listing_per_unit_title", title: transaction[:listing_title], unit_type: unit_type)
      else
        transaction[:listing_title]
      end
      listing_price = ar_transaction.listing_price || transaction[:listing_price]

      from = community_specific_sender(community, ar_transaction)
      hotel_guest = transaction_model.starter.is_hotel_guest? || transaction_model.starter.hotel_guest?
      mail(:to => seller_model.confirmed_notification_emails_to,
           :from => from,
           :subject => t("emails.new_payment.new_payment")) do |format|
        format.html {
          render "payment_receipt_to_seller", locals: {
                   conversation_url: person_transaction_url(seller_model, @url_params.merge(id: transaction[:id])),
                   listing_title: listing_title,
                   product_title: transaction[:listing_title],
                   price_per_unit_title: t("emails.new_payment.price_per_unit_type", unit_type: unit_type),
                   quantity_selector_label: quantity_selector_label,
                   listing_price: MoneyViewUtils.to_humanized(listing_price),
                   listing_quantity: transaction[:listing_quantity],
                   duration: transaction[:booking].present? ? transaction[:booking][:duration] : nil,
                   subtotal: MoneyViewUtils.to_humanized(transaction[:item_total]),
                   payment_total: MoneyViewUtils.to_humanized(payment_total),
                   shipping_total: MoneyViewUtils.to_humanized(transaction[:shipping_price]),
                   payment_service_fee: MoneyViewUtils.to_humanized(-service_fee),
                   payment_gateway_fee: MoneyViewUtils.to_humanized(-gateway_fee),
                   payment_gateway_fee_value: gateway_fee,
                   payment_seller_gets: MoneyViewUtils.to_humanized(you_get),
                   payer_full_name: buyer_model.name(community),
                   payer_given_name: PersonViewUtils.person_display_name_for_type(buyer_model, "first_name_only"),
                   gateway: transaction[:payment_gateway],
                   listing_availability: transaction[:availability],
                   listing: transaction_model.listing,
                   booking: transaction_model.booking,
                   deposit: (deposit ? MoneyViewUtils.to_humanized(deposit) : nil),
                   starter_hotel: hotel_guest ? transaction_model.starter : nil,
                   tx_model: transaction_model
                 },
                                              layout: 'email_v2'

        }
      end
    end
  end

  # seller_model, buyer_model and community can be passed as params for testing purposes
  def payment_receipt_to_buyer(transaction, seller_model = nil, buyer_model = nil, community = nil)
    seller_model ||= Person.find(transaction[:listing_author_id])
    buyer_model ||= Person.find(transaction[:starter_id])
    community ||= Community.find(transaction[:community_id])
    transaction_model = Transaction.find(transaction[:id])
    listing_image = transaction_model.listing.listing_images.select{|li| li.image_ready? }.first

    ar_transaction = ::Transaction.find(transaction[:id])
    @person_white_label = ar_transaction.person_white_label
    ladera = @person_white_label&.ladera_enabled?
    prepare_template(community, buyer_model, "email_about_new_payments", ar_transaction)
    deposit = transaction[:deposit] && transaction[:deposit] > 0 && transaction[:booking].present? ? transaction[:deposit] : nil
    with_locale(buyer_model.locale, community.locales.map(&:to_sym), community.id) do

      unit_type = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_unit(t[:unit_type], t[:unit_tr_key]) }.or_else(nil)
      quantity_selector_label = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_quantity(t[:unit_type], t[:unit_selector_tr_key]) }.or_else(nil)
      listing_title = if transaction[:booking].try(:[], :per_hour)
        t("emails.receipt_to_payer.listing_per_unit_title", title: transaction[:listing_title], unit_type: unit_type)
      else
        transaction[:listing_title]
      end
      listing_title = transaction[:listing_title] if ladera
      listing_price = ar_transaction.listing_price || transaction[:listing_price]
      person_count = ladera ? transaction[:listing_quantity] : 0
      for_person = I18n.t('emails.receipt_to_payer.for_person', count: person_count)
      transaction_params = {id: transaction_model.id}
      transaction_params[:token] = buyer_model.id.to_s if buyer_model.guest?


      recipient_emails = buyer_model.guest? ? [buyer_model.primary_email.address] : buyer_model.confirmed_notification_emails_to

      from = community_specific_sender(community, ar_transaction)
      hotel_guest = transaction_model.starter.is_hotel_guest? || transaction_model.starter.hotel_guest?
      mail(:to => recipient_emails,
           :from => from,
           :subject => t("emails.receipt_to_payer.receipt_of_payment")) { |format|
        format.html {
          render "payment_receipt_to_buyer", locals: {
                   conversation_url: person_transaction_url(buyer_model, @url_params.merge(transaction_params)),
                   listing_title: listing_title,
                   product_title: transaction[:listing_title],
                   price_per_unit_title: t("emails.receipt_to_payer.price_per_unit_type", unit_type: unit_type),
                   quantity_selector_label: quantity_selector_label,
                   listing_price: MoneyViewUtils.to_humanized(listing_price),
                   listing_quantity: transaction[:listing_quantity],
                   duration: transaction[:booking].present? ? transaction[:booking][:duration] : nil,
                   subtotal: MoneyViewUtils.to_humanized(transaction[:item_total]),
                   shipping_total: MoneyViewUtils.to_humanized(transaction[:shipping_price]),
                   payment_total: MoneyViewUtils.to_humanized(transaction[:payment_total]),
                   recipient_full_name: seller_model.name(community),
                   recipient_given_name: PersonViewUtils.person_display_name_for_type(seller_model, "first_name_only"),
                   automatic_confirmation_days: nil,
                   show_money_will_be_transferred_note: false,
                   gateway: transaction[:payment_gateway],
                   listing: transaction_model.listing,
                   listing_image: listing_image,
                   booking: transaction_model.booking,
                   deposit: (deposit ? MoneyViewUtils.to_humanized(deposit) : nil),
                   starter_hotel: hotel_guest ? transaction_model.starter : nil,
                   tx_model: transaction_model,
                   for_person: for_person
                 },
                                             layout: 'email_v2'

        }
      }
    end
  end

  # seller_model, buyer_model and community can be passed as params for testing purposes
  def cancel_receipt_to_buyer(transaction, seller_model = nil, buyer_model = nil, community = nil)
    seller_model ||= Person.find(transaction[:listing_author_id])
    buyer_model ||= Person.find(transaction[:starter_id])
    community ||= Community.find(transaction[:community_id])
    transaction_model = Transaction.find(transaction[:id])
    listing_image = transaction_model.listing.listing_images.select{|li| li.image_ready? }.first

    ar_transaction = ::Transaction.find(transaction[:id])
    @person_white_label = ar_transaction.person_white_label
    prepare_template(community, buyer_model, "email_about_new_payments", ar_transaction)
    deposit = transaction[:deposit] && transaction[:deposit] > 0 && transaction[:booking].present? ? transaction[:deposit] : nil
    with_locale(buyer_model.locale, community.locales.map(&:to_sym), community.id) do

      unit_type = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_unit(t[:unit_type], t[:unit_tr_key]) }.or_else(nil)
      quantity_selector_label = Maybe(transaction).select { |t| t[:unit_type].present? }.map { |t| ListingViewUtils.translate_quantity(t[:unit_type], t[:unit_selector_tr_key]) }.or_else(nil)
      listing_title = if transaction[:booking].try(:[], :per_hour)
        t("emails.receipt_to_payer.listing_per_unit_title", title: transaction[:listing_title], unit_type: unit_type)
      else
        transaction[:listing_title]
      end
      listing_price = ar_transaction.listing_price || transaction[:listing_price]
      transaction_params = {id: transaction_model.id}
      transaction_params[:token] = buyer_model.id.to_s if buyer_model.guest?

      recipient_emails = buyer_model.guest? ? [buyer_model.primary_email.address] : buyer_model.confirmed_notification_emails_to
      payment = transaction_model.stripe_payment

      from = community_specific_sender(community, ar_transaction)
      mail(:to => recipient_emails,
           :from => from,
           :subject => t("emails.receipt_to_payer.cancellation_of_payment")) { |format|
        format.html {
          render "cancel_receipt_to_buyer", locals: {
                   conversation_url: person_transaction_url(buyer_model, @url_params.merge(transaction_params)),
                   listing_title: listing_title,
                   product_title: transaction[:listing_title],
                   price_per_unit_title: t("emails.receipt_to_payer.price_per_unit_type", unit_type: unit_type),
                   quantity_selector_label: quantity_selector_label,
                   listing_price: MoneyViewUtils.to_humanized(listing_price),
                   listing_quantity: transaction[:listing_quantity],
                   duration: transaction[:booking].present? ? transaction[:booking][:duration] : nil,
                   subtotal: MoneyViewUtils.to_humanized(transaction[:item_total]),
                   shipping_total: MoneyViewUtils.to_humanized(transaction[:shipping_price]),
                   payment_total: MoneyViewUtils.to_humanized(transaction[:payment_total]),
                   recipient_full_name: seller_model.name(community),
                   recipient_given_name: PersonViewUtils.person_display_name_for_type(seller_model, "first_name_only"),
                   automatic_confirmation_days: nil,
                   show_money_will_be_transferred_note: false,
                   gateway: transaction[:payment_gateway],
                   listing: transaction_model.listing,
                   listing_image: listing_image,
                   booking: transaction_model.booking,
                   deposit: (deposit ? MoneyViewUtils.to_humanized(deposit) : nil),
                   refund_sum: MoneyViewUtils.to_humanized(payment.refund_amount)
                 },
                                            layout: 'email_v2'
        }
      }
    end
  end

  def free_receipt_to_seller(transaction)
    seller = transaction.author
    buyer = transaction.starter
    community = transaction.community
    @person_white_label = transaction.person_white_label

    prepare_template(community, seller, "email_about_new_payments", transaction)
    with_locale(seller.locale, community.locales.map(&:to_sym), community.id) do

      unit_type = ListingViewUtils.translate_unit(transaction.unit_type, transaction.unit_tr_key)
      quantity_selector_label = ListingViewUtils.translate_quantity(transaction.unit_type)
      listing_title = if transaction.booking&.per_hour?
        t("emails.free_receipt_to_seller.listing_per_unit_title", title: transaction.listing_title, unit_type: unit_type)
      else
        transaction.listing_title
      end

      mail(to: seller.confirmed_notification_emails_to,
           from: community_specific_sender(community, transaction),
           subject: t("emails.free_receipt_to_seller.subject", listing_title: listing_title)) do |format|
        format.html {
          render "free_receipt_to_seller", locals: {
           transaction_url: person_transaction_url(seller, @url_params.merge(id: transaction.id)),
           listing_title: listing_title,
           price_per_unit_title: t("emails.free_receipt_to_seller.price_per_unit_type", unit_type: unit_type),
           quantity_selector_label: quantity_selector_label,
           listing_price: MoneyViewUtils.to_humanized(transaction.unit_price),
           listing_quantity: transaction.listing_quantity,
           duration: transaction.booking&.duration,
           payer_full_name: buyer.name(community),
           payer_given_name: PersonViewUtils.person_display_name_for_type(buyer, "first_name_only"),
           listing_availability: transaction.availability,
           listing: transaction.listing,
           booking: transaction.booking,
           starter_hotel: transaction.starter.is_hotel_guest? ? transaction.starter : nil
         },
                                           layout: 'email_v2'
        }
      end
    end
  end

  def free_receipt_to_buyer(transaction)
    seller = transaction.author
    buyer = transaction.starter
    community = transaction.community
    listing_image = transaction.listing.listing_images.select{|li| li.image_ready? }.first
    @person_white_label = transaction.person_white_label
    ladera = @person_white_label&.ladera_enabled?

    prepare_template(community, buyer, "email_about_new_payments", transaction)
    with_locale(buyer.locale, community.locales.map(&:to_sym), community.id) do

      unit_type = ListingViewUtils.translate_unit(transaction.unit_type, transaction.unit_tr_key)
      quantity_selector_label = ListingViewUtils.translate_quantity(transaction.unit_type)
      listing_title = if transaction.booking&.per_hour?
        t("emails.free_receipt_to_buyer.listing_per_unit_title", title: transaction.listing_title, unit_type: unit_type)
      else
        transaction.listing_title
      end
      listing_title = transaction.listing_title if ladera
      person_count = ladera ? transaction.listing_quantity : 0
      for_person = I18n.t('emails.receipt_to_payer.for_person', count: person_count)
      transaction_params = {id: transaction.id}
      transaction_params[:token] = buyer.id.to_s if buyer.guest?


      recipient_emails = buyer.guest? ? [buyer.primary_email.address] : buyer.confirmed_notification_emails_to

      mail(:to => recipient_emails,
           :from => community_specific_sender(community, transaction),
           :subject => t("emails.free_receipt_to_buyer.subject")) { |format|
        format.html {
          render "free_receipt_to_buyer", locals: {
            transaction_url: person_transaction_url(buyer, @url_params.merge(transaction_params)),
            listing_title: listing_title,
            price_per_unit_title: t("emails.free_receipt_to_buyer.price_per_unit_type", unit_type: unit_type),
            quantity_selector_label: quantity_selector_label,
            listing_price: MoneyViewUtils.to_humanized(transaction.unit_price),
            listing_quantity: transaction.listing_quantity,
            duration: transaction.booking&.duration,
            recipient_full_name: seller.name(community),
            recipient_given_name: PersonViewUtils.person_display_name_for_type(seller, "first_name_only"),
            listing: transaction.listing,
            listing_image: listing_image,
            booking: transaction.booking,
            starter_hotel: transaction.starter.is_hotel_guest? ? transaction.starter : nil,
            for_person: for_person
         },
                                          layout: 'email_v2'
        }
      }
    end
  end

  def booking_changed(transaction, sender_is_buyer)
    seller = transaction.author
    buyer = transaction.starter
    community = transaction.community
    @person_white_label = transaction.person_white_label

    prepare_template(community, (sender_is_buyer ? seller : buyer), "booking_changed", transaction)
    with_locale(buyer.locale, community.locales.map(&:to_sym), community.id) do

      locals = template_locals(transaction, sender_is_buyer)

      mail(:to => locals[:recipient_emails],
           :from => community_specific_sender(community, transaction),
           :subject => t("emails.booking_changed.subject", listing_title: locals[:listing_title])) { |format|
        format.html {
          render "booking_changed", locals: locals,
                                    layout: 'email_v2'
        }
      }
    end
  end

  private

  def premailer_mail(opts, &)
    premailer(mail(opts.merge(skip_premailer: true), &))
  end

  # TODO Get rid of this method. Pass all data in local variables, not instance variables.
  def prepare_template(community, recipient, email_type = nil, transaction = nil)
    @email_type = email_type
    @community = community
    @current_community = community
    @recipient = recipient
    @url_params = build_url_params(community, recipient, transaction)

    if transaction&.person_white_label.present?
      @show_branding_info = false
    else
      @show_branding_info = !PlanService::API::Api.plans.get_current(community_id: community.id).data[:features][:whitelabel]
    end
  end

  def mail_params(recipient, from, subject)
    recipient_emails = recipient.guest? ? [recipient.primary_email.address] : recipient.confirmed_notification_emails_to
    {
      to: recipient_emails,
      from: from,
      subject: subject
    }
  end

  def build_url_params(community, recipient, transaction = nil)
    {
      host: transaction&.person_white_label&.full_domain || community.full_domain,
      ref: "email",
      locale: recipient.locale
    }
  end

  def template_locals(transaction, sender_is_buyer = true)
    seller = transaction.author
    buyer = transaction.starter
    community = transaction.community
    listing_image = transaction.listing.listing_images.select{|li| li.image_ready? }.first
    person_white_label = transaction.person_white_label
    ladera = person_white_label&.ladera_enabled?
    unit_type = ListingViewUtils.translate_unit(transaction.unit_type, transaction.unit_tr_key)
    quantity_selector_label = ListingViewUtils.translate_quantity(transaction.unit_type)
    listing_title = if transaction.booking&.per_hour?
      t("emails.free_receipt_to_buyer.listing_per_unit_title", title: transaction.listing_title, unit_type: unit_type)
    else
      transaction.listing_title
    end
    listing_title = transaction.listing_title if ladera
    person_count = ladera ? transaction.listing_quantity : 0
    for_person = I18n.t('emails.receipt_to_payer.for_person', count: person_count)
    transaction_params = {id: transaction.id}
    transaction_params[:token] = buyer.id.to_s if buyer.guest?

    recipient = sender_is_buyer ? seller : buyer
    recipient_emails = if sender_is_buyer
      seller.confirmed_notification_emails_to
    else
      buyer.guest? ? [buyer.primary_email.address] : buyer.confirmed_notification_emails_to
    end

    {
      recipient_emails: recipient_emails,
      transaction_url: person_transaction_url(recipient, @url_params.merge(transaction_params)),
      listing_title: listing_title,
      price_per_unit_title: t("emails.free_receipt_to_buyer.price_per_unit_type", unit_type: unit_type),
      quantity_selector_label: quantity_selector_label,
      listing_price: MoneyViewUtils.to_humanized(transaction.unit_price),
      listing_quantity: transaction.listing_quantity,
      duration: transaction.booking&.duration,
      recipient_full_name: recipient.name(community),
      recipient_given_name: PersonViewUtils.person_display_name_for_type(recipient, "first_name_only"),
      listing: transaction.listing,
      listing_image: listing_image,
      booking: transaction.booking,
      starter_hotel: transaction.starter.is_hotel_guest? ? transaction.starter : nil,
      for_person: for_person,
      other_party_name: (sender_is_buyer ? buyer : seller).name(community)
    }
  end
end
