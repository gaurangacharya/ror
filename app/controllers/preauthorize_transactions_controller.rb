# coding: utf-8
# rubocop:disable Metrics/ClassLength
class PreauthorizeTransactionsController < ApplicationController
  include EnsureGuestUser

  before_action do |controller|
    # controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_do_a_transaction")
  end

  before_action :ensure_listing_is_open
  before_action :ensure_listing_author_is_not_current_user
  before_action :ensure_author_is_confirmed
  before_action :ensure_authorized_to_reply
  before_action :ensure_can_receive_payment
  before_action :create_guest_person_and_pseido_sign_up, only: [:initiated]
  before_action :ensure_fake_current_user, only: [:initiate]
  before_action :ensure_logged_in_or_guest, except: [:initiate]
  before_action :allow_iframe

  IS_POSITIVE = ->(v) {
    return if v.nil?
    unless v.positive?
      {code: :positive_integer, msg: "Value must be a positive integer"}
    end
  }

  PARSE_DATE = ->(v) {
    return if v.nil?
    begin
      TransactionViewUtils.parse_booking_date(v)
    rescue ArgumentError => e
      # The transformator has to return something else than `Date` or
      # `nil` so that the `date` validator know that it's not a valid
      # date
      e
    end
  }

  PARSE_DATETIME = ->(v) {
    return if v.nil?
    begin
      TransactionViewUtils.parse_booking_datetime(v)
    rescue ArgumentError => e
      e
    end
  }

  NewTransactionParams = EntityUtils.define_builder(
    [:delivery, :to_symbol, one_of: [nil, :shipping, :pickup]],
    [:start_on, :date, transform_with: PARSE_DATE],
    [:end_on, :date, transform_with: PARSE_DATE],
    [:message, :string],
    [:quantity, :to_integer, validate_with: IS_POSITIVE],
    [:contract_agreed, transform_with: ->(v) { v == "1" }],
    [:tx_fields, :hash],
    [:guest_type, :string],
  )

  NewPerHourTransactionParams = EntityUtils.define_builder(
    [:start_time, :time, transform_with: PARSE_DATETIME],
    [:end_time, :time, transform_with: PARSE_DATETIME],
    [:message, :string],
    [:per_hour, transform_with: ->(v) { v == "1" }],
    [:contract_agreed, transform_with: ->(v) { v == "1" }],
    [:tx_fields, :hash],
    [:guest_type, :string],
  )

  NewPerHourTransactionParamsWithQuantity = EntityUtils.define_builder(
    [:start_time, :time, transform_with: PARSE_DATETIME],
    [:end_time, :time, transform_with: PARSE_DATETIME],
    [:per_hour, transform_with: ->(v) { v == "1" }],
    [:message, :string],
    [:quantity, :to_integer, validate_with: IS_POSITIVE],
    [:add_on_ids, :array],
    [:contract_agreed, transform_with: ->(v) { v == "1" }],
    [:tx_fields, :hash],
    [:guest_type, :string],
  )

  ListingQuery = MarketplaceService::Listing::Query

  class ItemTotal
    attr_reader :listing, :person, :tx_params

    def initialize(listing:, person:, tx_params:)
      @listing = listing
      @person = person
      @tx_params = tx_params
    end

    def total
      price_per_person * quantity
    end

    def price_per_person
      unit_price + add_ons_total
    end

    def unit_price
      @unit_price ||= begin
        base_price = if listing.is_ladera_listing? && tx_params[:guest_type].present?
                       calculated_price = listing.price_for_guest_type(tx_params[:guest_type])
                       Rails.logger.info "Calculated price for guest_type '#{tx_params[:guest_type]}': #{calculated_price}"
                       calculated_price
                     else
                       Rails.logger.info "Using standard price (not Ladera or no guest_type)"
                       listing.price
                     end
        
        person&.premium_pricing?(listing) ? (base_price / 2) : base_price
      end
    end

    def quantity
      @quantity ||= listing.calculate_tx_quantity(tx_params)
    end

    def add_ons_total
      return @add_ons_total if defined?(@add_ons_total)

      @add_ons_total = 0
      if tx_params[:add_on_ids].is_a?(Array) && tx_params[:add_on_ids].any?
        tx_params[:add_on_ids].each do |add_on_id|
          if add_on = listing.add_ons.find(add_on_id)
            @add_ons_total += add_on.price_for_user(person)
          end
        end
      end

      @add_ons_total
    end
  end

  class ShippingTotal
    attr_reader :initial, :additional, :quantity

    def initialize(initial:, additional:, quantity:)
      @initial = initial || 0
      @additional = additional || 0
      @quantity = quantity
    end

    def total
      initial + (additional * (quantity - 1))
    end
  end

  class NoShippingFee
    def total
      0
    end
  end

  class OrderTotal
    attr_reader :item_total, :shipping_total, :listing

    def initialize(item_total:, shipping_total:, listing:)
      @item_total = item_total
      @shipping_total = shipping_total
      @listing = listing
    end

    def total
      result = subtotal + shipping_total.total
      result += tax if tax
      result += service_fee if service_fee
      result
    end

    def subtotal
      item_total.total
    end

    def tax
      listing.tax_percent.present? ? Money.new((subtotal.cents * listing.tax_percent.to_f / 100).floor(2), subtotal.currency) : nil
    end

    def service_fee
      listing.service_fee_percent.present? ? Money.new((subtotal.cents * listing.service_fee_percent.to_f / 100).floor(2), subtotal.currency) : nil
    end

    def subtotal_to_show
      item_total.total if show_subtotal?
    end

    def show_subtotal?
      subtotal != item_total.unit_price
    end
  end

  module Validator

    module_function

    def validate_initiate_params(marketplace_uuid:,
                                 listing_uuid:,
                                 tx_params:,
                                 quantity_selector:,
                                 shipping_enabled:,
                                 pickup_enabled:,
                                 availability_enabled:,
                                 listing:,
                                 availability_per_hour_enabled:)

      validate_delivery_method(tx_params: tx_params, shipping_enabled: shipping_enabled, pickup_enabled: pickup_enabled)
        .and_then { validate_booking(tx_params: tx_params, quantity_selector: quantity_selector, listing: listing) }
        .and_then { |result|
          if listing.restricts_quantity? && !listing.enough_quantity?(tx_params[:quantity])
            Result::Error.new(nil, code: :bad_quantity, tx_params: tx_params)
          elsif availability_per_hour_enabled && tx_params[:per_hour]
            validate_booking_per_hour_timeslots(listing: listing, tx_params: tx_params)
          elsif availability_enabled
            validate_booking_timeslots(tx_params: tx_params,
                                       marketplace_uuid: marketplace_uuid,
                                       listing_uuid: listing_uuid,
                                       quantity_selector: quantity_selector,
                                       listing: listing)
          else
            Result::Success.new(result)
          end
      }
    end

    def validate_initiated_params(tx_params:,
                                  quantity_selector:,
                                  shipping_enabled:,
                                  pickup_enabled:,
                                  transaction_agreement_in_use:,
                                  user:,
                                  user_params:,
                                  listing:)

      validate_delivery_method(tx_params: tx_params, shipping_enabled: shipping_enabled, pickup_enabled: pickup_enabled)
        .and_then { validate_booking(tx_params: tx_params, quantity_selector: quantity_selector) }
        .and_then { validate_transaction_agreement(tx_params: tx_params, transaction_agreement_in_use: transaction_agreement_in_use) }
        .and_then { validate_guest_or_user(user, tx_params, user_params) }
        .and_then { |result|
          if listing.restricts_quantity? && !listing.enough_quantity?(tx_params[:quantity])
            Result::Error.new(nil, code: :bad_quantity, tx_params: tx_params)
          else
            Result::Success.new(result)
          end
        }
    end

    def validate_guest_or_user(user, tx_params, user_params)
      if user.guest?
        if user_params.blank?
          Result::Error.new(nil, code: :user_data_missing, tx_params: tx_params)
        elsif user_params[:email].blank?
          Result::Error.new(nil, code: :user_data_missing, tx_params: tx_params)
        elsif user_params[:last_name].blank?
          Result::Error.new(nil, code: :user_data_missing, tx_params: tx_params)
        elsif user_params[:first_name].blank?
          Result::Error.new(nil, code: :user_data_missing, tx_params: tx_params)
        else
          Result::Success.new(tx_params)
        end
      else
        Result::Success.new(tx_params)
      end
    end

    def validate_delivery_method(tx_params:, shipping_enabled:, pickup_enabled:)
      delivery = tx_params[:delivery]

      case [delivery, shipping_enabled, pickup_enabled]
      when matches([:shipping, true])
        Result::Success.new(tx_params.merge(delivery: :shipping))
      when matches([:pickup, __, true])
        Result::Success.new(tx_params.merge(delivery: :pickup))
      when matches([nil, false, false])
        Result::Success.new(tx_params.merge(delivery: :nil))
      else
        Result::Error.new(nil, code: :delivery_method_missing, tx_params: tx_params)
      end
    end

    def validate_booking(tx_params:, quantity_selector:, listing: nil)
      has_paypal_soap_account = listing.try(:author).try(:paypal_soap_account).try(:filled?)
      per_hour = tx_params[:per_hour]
      if per_hour || [:day, :night].include?(quantity_selector)
        start_on, end_on = per_hour ? tx_params.values_at(:start_time, :end_time)  : tx_params.values_at(:start_on, :end_on)

        if start_on.nil? || end_on.nil?
          Result::Error.new(nil, code: :dates_missing, tx_params: tx_params)
        elsif start_on > end_on
          Result::Error.new(nil, code: :end_cant_be_before_start, tx_params: tx_params)
        elsif start_on == end_on
          code = per_hour ? :at_least_one_hour_required : :at_least_one_day_or_night_required
          Result::Error.new(nil, code: code, tx_params: tx_params)
        elsif !has_paypal_soap_account && StripeHelper.stripe_active?(tx_params[:marketplace_id]) && end_on > APP_CONFIG.stripe_max_booking_date.days.from_now
          Result::Error.new(nil, code: :date_too_late, tx_params: tx_params)
        else
          Result::Success.new(tx_params)
        end
      else
        Result::Success.new(tx_params)
      end
    end


    def validate_booking_timeslots(tx_params:, marketplace_uuid:, listing_uuid:, quantity_selector:, listing:)
      start_on, end_on = tx_params.values_at(:start_on, :end_on)
      duration = DateUtils.duration(start_on, end_on)
      if duration < listing.min_units
        return Result::Error.new(nil, code: :dates_not_available_units, min_units: listing.min_units, unit_type: listing.booking_mode)
      end
      if DateTimeSlotService.all_days_available_qty?(listing.id, start_on, end_on, tx_params[:quantity].to_i)
        Result::Success.new(tx_params)
      else
        Result::Error.new(nil, code: :dates_not_available)
      end
    end

    def validate_booking_per_hour_timeslots(listing:, tx_params:)
      return Result::Success.new(tx_params) if !tx_params[:per_hour]
      booking = Booking.new(tx_params.slice(:start_time, :end_time, :per_hour))
      slot = Listing::WorkingTimeSlot.new(listing: listing, start_time: booking.start_time, end_time: booking.end_time)
      if listing.working_hours_covers_booking?(booking) && slot.can_add_capacity?(tx_params[:quantity].to_i)
        if booking.duration >= listing.min_units
          if slot.current_max_hours >= booking.duration
            Result::Success.new(tx_params)
          else
            Result::Error.new(nil, code: :dates_not_available_past, min_units: listing.min_units, unit_type: listing.booking_mode)
          end
        else
          Result::Error.new(nil, code: :dates_not_available_units, min_units: listing.min_units, unit_type: listing.booking_mode)
        end
      else
        Result::Error.new(nil, code: :dates_not_available)
      end
    end

    def validate_transaction_agreement(tx_params:, transaction_agreement_in_use:)
      contract_agreed = tx_params[:contract_agreed]

      if transaction_agreement_in_use
        if contract_agreed
          Result::Success.new(tx_params)
        else
          Result::Error.new(nil, code: :agreement_missing, tx_params: tx_params)
        end
      else
        Result::Success.new(tx_params)
      end
    end
  end

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def initiate
    params_validator =
      if params_per_hour?
        listing.need_quantity_input? ? NewPerHourTransactionParamsWithQuantity : NewPerHourTransactionParams
      else
        NewTransactionParams
      end

    validation_result = params_validator.validate(params).and_then { |params_entity|
      tx_params = add_defaults(
        params: params_entity,
        shipping_enabled: listing.require_shipping_address,
        pickup_enabled: listing.pickup_enabled)
      tx_params[:marketplace_id] = @current_community.id

      Validator.validate_initiate_params(marketplace_uuid: @current_community.uuid_object,
                                         listing_uuid: listing.uuid_object,
                                         tx_params: tx_params,
                                         quantity_selector: listing.booking_quantity_selector&.to_sym,
                                         shipping_enabled: listing.require_shipping_address,
                                         pickup_enabled: listing.pickup_enabled,
                                         availability_enabled: listing.availability.to_sym == :booking,
                                         listing: listing,
                                         availability_per_hour_enabled: availability_per_hour_enabled)
    }

    validation_result.on_success { |tx_params|
      is_booking = is_booking?(listing)

      quantity = listing.calculate_tx_quantity(tx_params)
      duration = listing.calculate_tx_duration(tx_params)

      listing_entity = ListingQuery.listing(params[:listing_id])

      item_total = ItemTotal.new(
        listing: listing,
        person: current_person,
        tx_params: tx_params
      )

      shipping_total = calculate_shipping_from_entity(tx_params: tx_params, listing_entity: listing_entity, quantity: quantity)
      order_total = OrderTotal.new(
        listing: listing,
        item_total: item_total,
        shipping_total: shipping_total
      )

      record_event(
        flash.now,
        "InitiatePreauthorizedTransaction",
        { listing_id: listing.id,
          listing_uuid: listing.uuid_object.to_s })

      render "listing_conversations/initiate",
             locals: {
               start_on: tx_params[:start_on],
               end_on: tx_params[:end_on],
               start_time: tx_params[:start_time],
               end_time:   tx_params[:end_time],
               per_hour:   tx_params[:per_hour],
               add_on_ids: tx_params[:add_on_ids],
               listing: listing_entity,
               listing_model: listing,
               delivery_method: tx_params[:delivery],
               quantity: tx_params[:quantity],
               author: query_person_entity(listing_entity[:author_id]),
               action_button_label: translate(listing_entity[:action_button_tr_key]),
               paypal_in_use: PaypalHelper.user_and_community_ready_for_payments?(listing.author_id, @current_community.id),
               paypal_expiration_period: MarketplaceService::Transaction::Entity.authorization_expiration_period(:stripe),
               stripe_in_use: StripeHelper.user_and_community_ready_for_payments?(listing.author_id, @current_community.id),
               stripe_publishable_key: StripeHelper.publishable_key(@current_community.id),
               stripe_shipping_required: listing.require_shipping_address && tx_params[:delivery] != :pickup,
               form_action: initiated_order_path(person_id: @current_user.id, listing_id: listing_entity[:id]),
               country_code: LocalizationUtils.valid_country_code(@current_community.country),
               paypal_analytics_event: [
                 "RedirectingBuyerToPayPal",
                 { listing_id: listing.id,
                   listing_uuid: listing.uuid_object.to_s,
                   community_id: @current_community.id,
                   marketplace_uuid: @current_community.uuid_object.to_s,
                   user_logged_in: @current_user.present? }],
               price_break_down_locals:TransactionViewUtils.price_break_down_locals(
                 availability: listing.availability,
                 booking:  is_booking,
                 quantity: quantity,
                 start_on: tx_params[:start_on],
                 end_on:   tx_params[:end_on],
                 duration: duration,
                 listing_price: item_total.unit_price,
                 localized_unit_type: translate_unit_from_listing(listing_entity),
                 localized_selector_label: translate_selector_label_from_listing(listing_entity),
                 subtotal: order_total.subtotal_to_show,
                 shipping_price: shipping_price_to_show(tx_params[:delivery], shipping_total),
                 total: order_total.total,
                 unit_type: listing.booking? ? listing.booking_mode.to_sym : listing.unit_type,
                 start_time: tx_params[:start_time],
                 end_time:   tx_params[:end_time],
                 per_hour:   tx_params[:per_hour],
                 deposit: listing.deposit.present? && listing.deposit > 0 ? listing.deposit : nil,
                 deposit_status: nil,
                 add_on_ids: tx_params[:add_on_ids],
                 tax_percent: listing.tax_percent,
                 tax: order_total.tax,
                 service_fee_percent: listing.service_fee_percent,
                 service_fee: order_total.service_fee,
               ),
             }
    }

    validation_result.on_error { |msg, data|
      error_msg =
        if data.is_a?(Array)
          # Entity validation failed
          t("listing_conversations.preauthorize.invalid_parameters")
        elsif [:dates_missing,
               :end_cant_be_before_start,
               :delivery_method_missing,
               :at_least_one_day_or_night_required,
               :at_least_one_hour_required,
               :date_too_late
              ].include?(data[:code])
          t("listing_conversations.preauthorize.invalid_parameters")
        elsif data[:code] == :dates_not_available
          t("listing_conversations.preauthorize.dates_not_available")
        elsif data[:code] == :dates_not_available_past
          t("listing_conversations.preauthorize.dates_not_available_past")
        elsif data[:code] == :dates_not_available_units
          t("listing_conversations.preauthorize.dates_not_available_units", min_units: data[:min_units], unit_type: data[:unit_type])

        elsif data[:code] == :user_data_missing
          t("listing_conversations.preauthorize.user_data_missing")
        elsif data[:code] == :bad_quantity
          if listing.min_quantity > data[:tx_params][:quantity].to_i
            t("listings.bad_quantity_min", min: listing.min_quantity)
          else
            t("listings.bad_quantity_max", max: listing.max_quantity)
          end
        else
          raise NotImplementedError.new("No error handler for: #{msg}, #{data.inspect}")
        end

      flash[:error] = error_msg
      logger.error(msg, :transaction_initiate_error, data)
      redirect_to listing_path(listing.id)
    }
  end

  def initiated
    params_validator =
      if params_per_hour?
        listing.need_quantity_input? ? NewPerHourTransactionParamsWithQuantity : NewPerHourTransactionParams
      else
        NewTransactionParams
      end

    validation_result = params_validator.validate(params).and_then { |params_entity|
      tx_params = add_defaults(
        params: params_entity,
        shipping_enabled: listing.require_shipping_address,
        pickup_enabled: listing.pickup_enabled)

      is_booking = is_booking?(listing)

      Validator.validate_initiated_params(tx_params: tx_params,
                                          quantity_selector: listing.booking_quantity_selector&.to_sym,
                                          shipping_enabled: listing.require_shipping_address,
                                          pickup_enabled: listing.pickup_enabled,
                                          transaction_agreement_in_use: @current_community.transaction_agreement_in_use?,
                                          user: @current_user,
                                          user_params: params[:user],
                                          listing: listing)
    }

    validation_result.on_success { |tx_params|
      is_booking = is_booking?(listing)

      quantity = listing.calculate_tx_quantity(tx_params)
      shipping_total = calculate_shipping_from_model(tx_params: tx_params, listing_model: listing, quantity: quantity)

      buyer = if @current_user.is_hotel?
        guest = create_guest_person
        guest.update_columns(hotel_id @current_user.id)
        guest
      else
        @current_user
      end

      # Handle Ladera guest type selection
      if params[:guest_type].present?
        case params[:guest_type]
        when 'hotel_guest'
          buyer.update_column(:hotel_guest, true) if buyer.respond_to?(:hotel_guest)
        when 'visitor'
          buyer.update_column(:hotel_guest, false) if buyer.respond_to?(:hotel_guest)
        else
          Rails.logger.warn "Invalid guest_type parameter: #{params[:guest_type]}"
        end
      end

      tx_response = create_preauth_transaction(
        payment_type: params[:payment_type].to_sym,
        community: @current_community,
        listing: listing,
        listing_quantity: quantity,
        user: buyer,
        content: tx_params[:message],
        force_sync: !request.xhr?,
        delivery_method: tx_params[:delivery],
        shipping_price: shipping_total.total,
        booking_fields: {
          start_on: tx_params[:start_on],
          end_on: tx_params[:end_on],
          start_time: tx_params[:start_time],
          end_time:   tx_params[:end_time],
          per_hour:   tx_params[:per_hour],
        },
        confirmed_availability: params[:confirmed_availability] == '1',
        tx_params: tx_params,
      )

      handle_tx_response(tx_response, params[:payment_type].to_sym)
    }

    validation_result.on_error { |msg, data|
      error_msg, path =
        if data.is_a?(Array)
          # Entity validation failed
          logger.error(msg, :transaction_initiated_error, data)
          [t("listing_conversations.preauthorize.invalid_parameters"), listing_path(listing.id)]

        elsif [:dates_missing, :end_cant_be_before_start, :delivery_method_missing, :at_least_one_day_or_night_required, :at_least_one_hour_required].include?(data[:code])
          logger.error(msg, :transaction_initiated_error, data)
          [t("listing_conversations.preauthorize.invalid_parameters"), listing_path(listing.id)]
        elsif data[:code] == :agreement_missing
          # User error, no logging here
          [t("error_messages.transaction_agreement.required_error"), error_path(data[:tx_params])]
        elsif data[:code] == :user_data_missing
          # User error, no logging here
          [t("listing_conversations.preauthorize.user_data_missing"), error_path(data[:tx_params])]
        elsif data[:code] == :bad_quantity
          if listing.min_quantity > data[:tx_params][:quantity].to_i
            t("listings.bad_quantity_min", min: listing.min_quantity)
          else
            t("listings.bad_quantity_max", max: listing.max_quantity)
          end
        else
          raise NotImplementedError.new("No error handler for: #{msg}, #{data.inspect}")
        end

      render_error_response(request.xhr?, error_msg, path)
    }
  end

  private

  def calculate_shipping_from_entity(tx_params:, listing_entity:, quantity:)
    calculate_shipping(
      tx_params: tx_params,
      initial: listing_entity[:shipping_price],
      additional: listing_entity[:shipping_price_additional],
      quantity: quantity)
  end

  def calculate_shipping_from_model(tx_params:, listing_model:, quantity:)
    calculate_shipping(
      tx_params: tx_params,
      initial: listing_model.shipping_price,
      additional: listing_model.shipping_price_additional,
      quantity: quantity)
  end

  def calculate_shipping(tx_params:, initial:, additional:, quantity:)
    if tx_params[:delivery] == :shipping
      ShippingTotal.new(
        initial: initial,
        additional: additional,
        quantity: quantity)
    else
      NoShippingFee.new
    end
  end

  def add_defaults(params:, shipping_enabled:, pickup_enabled:)
    default_shipping =
      case [shipping_enabled, pickup_enabled]
      when [true, false]
        {delivery: :shipping}
      when [false, true]
        {delivery: :pickup}
      when [false, false]
        {delivery: nil}
      else
        {}
      end

    params.merge(default_shipping)
  end

  def handle_tx_response(tx_response, gateway)
    if !tx_response[:success]
      render_error_response(request.xhr?, t("error_messages.#{gateway}.generic_error"), action: :initiate)
    elsif (tx_response[:data][:gateway_fields][:redirect_url])
      xhr_json_redirect tx_response[:data][:gateway_fields][:redirect_url]
    elsif gateway == :stripe
      tx = Transaction.find(tx_response[:data][:transaction][:id])
      if tx.auto_confirm? || params[:confirmed_availability] == '1' && @current_user.is_hotel?
        TransactionService::Transaction.complete_preauthorization(community_id: tx.community_id,
                                                                  transaction_id: tx.id,
                                                                  message: nil,
                                                                  sender_id: tx.listing_author_id)
      end
      xhr_json_redirect person_transaction_path(@current_user, tx_response[:data][:transaction][:id])
    elsif gateway == :none
      tx = Transaction.find(tx_response[:data][:transaction][:id])
      xhr_json_redirect person_transaction_path(person_id: tx.starter.username, id: tx.id)
    elsif gateway == :paypal
      tx = Transaction.find(tx_response[:data][:transaction][:id])
      xhr_json_redirect checkout_paypal_service_checkout_path(tx.id)
    else
      render json: {
        op_status_url: transaction_op_status_path(tx_response[:data][:gateway_fields][:process_token]),
        op_error_msg: t("error_messages.#{gateway}.generic_error")
      }
    end
  end

  def xhr_json_redirect(redirect_url)
    if request.xhr?
      render json: { redirect_url: redirect_url }
    else
      redirect_to redirect_url
    end
  end

  def error_path(tx_params)
    booking_dates = HashUtils.map_values(tx_params.slice(:start_on, :end_on).compact) { |date|
      TransactionViewUtils.stringify_booking_date(date)
    }

    {action: :initiate}.merge(booking_dates)
  end

  def translate_unit_from_listing(listing)
    Maybe(listing).select { |l|
      l[:unit_type].present?
    }.map { |l|
      ListingViewUtils.translate_unit(l[:unit_type], l[:unit_tr_key])
    }.or_else(nil)
  end

  def translate_selector_label_from_listing(listing)
    Maybe(listing).select { |l|
      l[:unit_type].present?
    }.map { |l|
      ListingViewUtils.translate_quantity(l[:unit_type], l[:unit_selector_tr_key])
    }.or_else(nil)
  end

  def shipping_price_to_show(delivery_method, shipping_total)
    shipping_total.total if show_shipping_price?(delivery_method)
  end

  def show_shipping_price?(delivery_method)
    delivery_method == :shipping
  end

  def is_booking?(listing)
    listing.booking? 
  end

  def render_error_response(is_xhr, error_msg, redirect_params)
    if is_xhr
      render json: { error_msg: error_msg }
    else
      flash[:error] = error_msg
      redirect_to(redirect_params)
    end
  end

  def ensure_listing_author_is_not_current_user
    if listing.author == @current_user
      flash[:error] = t("layouts.notifications.you_cannot_send_message_to_yourself")
      redirect_to(session[:return_to_content] || search_path)
    end
  end

  # Ensure that only users with appropriate visibility settings can reply to the listing
  def ensure_authorized_to_reply
    unless listing.visible_to?(@current_user, @current_community, session[:admin_pretending])
      flash[:error] = t("layouts.notifications.you_are_not_authorized_to_view_this_content")
      redirect_to search_path
    end
  end

  def ensure_listing_is_open
    if listing.closed?
      flash[:error] = t("layouts.notifications.you_cannot_reply_to_a_closed_offer")
      redirect_to(session[:return_to_content] || search_path)
    end
  end

  def listing
    @listing ||= Listing.find_by(
      id: params[:listing_id], community_id: @current_community.id) or render_not_found!("Listing #{params[:listing_id]} not found from community #{@current_community.id}")
  end

  def ensure_can_receive_payment
    payment_type = if listing.free?
      :none
    else
      MarketplaceService::Community::Query.payment_type(@current_community.id) || :none
    end

    ready = TransactionService::Transaction.can_start_transaction(transaction: {
        payment_gateway: payment_type,
        community_id: @current_community.id,
        listing_author_id: listing.author.id
      })

    unless ready[:data][:result]
      flash[:error] = t("layouts.notifications.listing_author_payment_details_missing")

      record_event(
        flash,
        "ProviderPaymentDetailsMissing",
        { listing_id: listing.id,
          listing_uuid: listing.uuid_object.to_s })

      redirect_to listing_path(listing)
    end
  end

  def create_preauth_transaction(opts)
    forced_person = opts[:user]
    payment_process = :preauthorize
    case opts[:payment_type].to_sym
    when :paypal
      # PayPal doesn't like images with cache buster in the URL
      logo_url = Maybe(opts[:community])
               .wide_logo
               .select { |wl| wl.present? }
               .url(:paypal, timestamp: false)
               .or_else(nil)

      gateway_fields =
        {
          merchant_brand_logo_url: logo_url,
          success_url: success_paypal_service_checkout_orders_url,
          cancel_url: cancel_paypal_service_checkout_orders_url(listing_id: opts[:listing].id)
        }
    when :stripe
      gateway_fields =
        {
          stripe_email: @current_user.primary_email.address,
          stripe_token: params[:stripe_token],
          shipping_address: params[:shipping_address],
          service_name: @current_community.name_with_separator(I18n.locale)
        }
    when :none
      payment_process = :none
    end

    item_total = ItemTotal.new(
      listing: listing,
      person: forced_person,
      tx_params: opts[:tx_params]
    )
    real_price = item_total.price_per_person

    ref_id = params[:referral_id]
    ref_discount = nil
    if ref_id.present? && real_price && !opts[:user]&.premium_active?
      affiliate = Person.where(community_id: @current_community.id, referral_id: ref_id).first
      value = affiliate && affiliate.is_affiliate? ? @current_community.referral_discount : nil
      if value
        real_price = (100.0 - value)/100.0*real_price
        ref_discount = value
      end
    end

    add_on_ids = opts[:tx_params][:add_on_ids]
    add_ons_attributes = []
    if add_on_ids.is_a?(Array)
      add_ons_attributes = add_on_ids.map do |add_on_id|
        if add_on = listing.add_ons.find(add_on_id)
          {
            title: add_on.title,
            price: add_on.price_for_user(forced_person),
          }
        end
      end
    end
    fields_attributes = (opts[:tx_params][:tx_fields] || {}).values

    transaction = {
          community_id: opts[:community].id,
          community_uuid: opts[:community].uuid_object,
          listing_id: opts[:listing].id,
          listing_uuid: opts[:listing].uuid_object,
          listing_title: opts[:listing].title,
          starter_id: opts[:user].id,
          starter_uuid: opts[:user].uuid_object,
          listing_author_id: opts[:listing].author.id,
          listing_author_uuid: opts[:listing].author.uuid_object,
          listing_quantity: opts[:listing_quantity],
          unit_type: opts[:listing].unit_type,
          unit_price: real_price,
          unit_tr_key: opts[:listing].unit_tr_key,
          unit_selector_tr_key: opts[:listing].unit_selector_tr_key,
          availability: opts[:listing].availability,
          content: opts[:content],
          payment_gateway: opts[:payment_type].to_sym,
          payment_process: payment_process,
          booking_fields: opts[:booking_fields],
          delivery_method: opts[:delivery_method],
          deposit: opts[:listing].deposit,
          referral_id: ref_discount ? params[:referral_id] : nil,
          referral_discount: ref_discount,
          auto_confirm:  opts[:confirmed_availability] || opts[:listing].auto_confirm,
          person_white_label_id: listing.author.person_white_label&.id,
          add_ons_attributes: add_ons_attributes,
          tax_percent: listing.tax_percent,
          service_fee_percent: listing.service_fee_percent,
          listing_price: item_total.unit_price,
          fields_attributes: fields_attributes,
    }

    if(opts[:delivery_method] == :shipping)
      transaction[:shipping_price] = opts[:shipping_price]
    end
    TransactionService::Transaction.create({
        transaction: transaction,
        gateway_fields: gateway_fields
      },
      force_sync: opts[:payment_type] == :stripe || opts[:force_sync])
  end

  def query_person_entity(id)
    person_entity = MarketplaceService::Person::Query.person(id, @current_community.id)
    person_display_entity = person_entity.merge(
      display_name: PersonViewUtils.person_entity_display_name(person_entity, @current_community.name_display_type)
    )
  end

  def params_per_hour?
    params[:per_hour] == '1'
  end

  def availability_per_hour_enabled
    FeatureFlagHelper.feature_enabled?(:availability_per_hour)
  end

  def ensure_author_is_confirmed
    if !listing.author.is_confirmed? && listing.author.website_url.present?
      redirect_to listing.author.website_url
    end
  end
end
