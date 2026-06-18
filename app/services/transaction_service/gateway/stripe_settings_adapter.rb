module TransactionService::Gateway
  class StripeSettingsAdapter < SettingsAdapter

    PaymentSettingsStore = TransactionService::Store::PaymentSettings

    def configured?(community_id:, author_id:)
      payment_settings = Maybe(PaymentSettingsStore.get_active_by_gateway(community_id: community_id, payment_gateway: :stripe))
                         .select {|set| stripe_settings_configured?(set)}

      personal_account_verified = stripe_account_created?(community_id: community_id, person_id: author_id, settings: payment_settings)
      payment_settings_available = payment_settings.map {|_| true }.or_else(false)

      [personal_account_verified, payment_settings_available].all?
    end

    def tx_process_settings(opts_tx)
      currency = opts_tx[:unit_price].currency
      p_set = PaymentSettingsStore.get_active_by_gateway(community_id: opts_tx[:community_id], payment_gateway: :stripe)

      author = Person.find(opts_tx[:listing_author_id])
      buyer  = Person.find(opts_tx[:starter_id])
      community = Community.find(opts_tx[:community_id])

      if (buyer.is_hotel? || buyer.is_hotel_guest?) && author.is_affiliate? || opts_tx[:referral_id].present?
        own_affiliate = buyer.hotel && opts_tx[:referral_id].present? && opts_tx[:referral_id] == buyer.hotel.referral_id

        reseller_percent = buyer.is_hotel? || buyer.is_hotel_guest? && !own_affiliate ? community.hotel_percent_user : community.hotel_percent_guest
        platform_percent = buyer.is_hotel? || buyer.is_hotel_guest? && !own_affiliate ? community.hotel_percent_platform : community.platform_percent_guest
        {
          minimum_commission: Money.new(p_set[:minimum_transaction_fee_cents], currency),
          commission_from_seller: (platform_percent + reseller_percent).round,
          automatic_confirmation_after_days: p_set[:confirmation_after_days]
        }
      else
        {
          minimum_commission: Money.new(p_set[:minimum_transaction_fee_cents], currency),
          commission_from_seller: p_set[:commission_from_seller],
          automatic_confirmation_after_days: p_set[:confirmation_after_days]
        }
      end
    end

    private

    def stripe_settings_configured?(settings)
      settings[:payment_gateway] == :stripe && settings[:api_verified] && !!settings[:commission_from_seller] && !!settings[:minimum_price_cents]
    end

    def stripe_account_created?(community_id:, person_id: nil, settings: Maybe(nil))
      account = StripeService::API::Api.accounts.get(community_id: community_id, person_id: person_id).data
      account && account[:stripe_seller_id].present? && (account[:stripe_bank_id].present? || account[:account_type] == 'connect')
    end

  end
end
