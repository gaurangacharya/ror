#
# StripeAccount Store wraps ActiveRecord models and stores accounts to the database.
#
module StripeService::Store::StripeAccount
  StripeAccountModel = ::StripeAccount

  # Stripe is available only in some countries https://stripe.com/global, we restrict to US and EU only
  ALL_STRIPE_COUNTRIES = ["US", "GB", "AT", "BE", "CH", "DE", "DK", "ES", "FI", "FR", "IE", "IT", "LU", "NL", "NO", "PT", "SE", "CA", "SG", "HK", "JP", "BR", "MX", "AU", "NZ"]
  COUNTRIES = ALL_STRIPE_COUNTRIES & ::MarketplaceService::AvailableCurrencies::COUNTRY_SET_STRIPE_AND_PAYPAL

  VALID_BANK_CURRENCIES = ["CHF", "DKK", "EUR", "GBP", "NOK", "SEK", "USD", "JPY", "AUD", "HKD", "SGD", "NZD", "BRL", "MXN", "CAD" ]

  StripeAccountCreate = EntityUtils.define_builder(
    [:community_id, :mandatory, :fixnum],
    [:person_id, :optional, :string],
    [:stripe_seller_id, :string, :mandatory],
    [:account_type, :string]
  )

  StripeAccountUpdate = EntityUtils.define_builder(
    [:first_name, :string],
    [:last_name, :string],
    [:address_country, :string],
    [:address_city, :string],
    [:address_line1, :string],
    [:address_postal_code, :string],
    [:address_state, :string],
    [:birth_date, :date]
  )

  StripeAddressUpdate = EntityUtils.define_builder(
    [:address_city, :string],
    [:address_line1, :string],
    [:address_postal_code, :string],
    [:address_state, :string]
  )

  StripeAccount = EntityUtils.define_builder(
    [:community_id, :fixnum],
    [:person_id, :string],
    [:stripe_seller_id, :string],
    [:stripe_bank_id, :string],
    [:stripe_customer_id, :string],
    [:access_token, :string],
    [:refresh_token, :string],
    [:account_type, :string]
  )

  StripeBankAccount = EntityUtils.define_builder(
    [:stripe_bank_id, :string]
  )

  StripeConnectedAccount = EntityUtils.define_builder(
    [:community_id, :mandatory, :fixnum],
    [:person_id, :mandatory, :string],
    [:stripe_seller_id, :mandatory, :string],
    [:access_token, :string],
    [:refresh_token, :string],
    [:account_type, :string]
  )

  module_function

  def create(opts:)
    entity = StripeAccountCreate.call(opts.merge(account_type: 'managed'))
    account_model = StripeAccountModel.where(community_id: entity[:community_id], person_id: entity[:person_id]).first
    if account_model
      account_model.update(entity)
    else
      account_model = StripeAccountModel.create!(entity)
    end
    from_model(account_model)
  end

  def create_connected(opts:)
    entity = StripeConnectedAccount.call(opts.merge(account_type: 'connect'))
    account_model = StripeAccountModel.where(community_id: entity[:community_id], person_id: entity[:person_id]).first
    if account_model
      account_model.update(entity)
    else
      account_model = StripeAccountModel.create!(entity)
    end
    from_model(account_model)
  end

  def create_customer(opts:)
    account_model = StripeAccountModel.create!(opts.merge(account_type: 'customer'))
    from_model(account_model)
  end

  def update_bank_account(community_id:, person_id:, opts:)
    find_params = {
      community_id: community_id,
      person_id: person_id,
    }
    model = StripeAccountModel.where(find_params).first
    entity = StripeBankAccount.call(opts)
    model.update(entity)
    from_model(model)
  end

  def update_field(community_id:, person_id:, field:, value:)
    find_params = {
      community_id: community_id,
      person_id: person_id,
    }
    model = StripeAccountModel.where(find_params).first
    model.update(field => value)
    from_model(model)
  end

  def get(person_id: nil, community_id:)
    from_model(
      StripeAccountModel.where(
        person_id: person_id,
        community_id: community_id
      ).first
    )
  end

  def get_active_users(community_id:)
      StripeAccountModel.where(
        community_id: community_id
      )
        .where.not(person_id: nil)
        .map(&:person_id)
  end

  def from_model(model)
    Maybe(model)
      .map { |m| EntityUtils.model_to_hash(m) }
      .map { |hash| StripeAccount.call(hash) }
      .or_else(nil)
  end

  def destroy(person_id: nil, community_id:)
    StripeAccountModel.where(
      person_id: person_id,
      community_id: community_id
    ).delete_all
  end
end
