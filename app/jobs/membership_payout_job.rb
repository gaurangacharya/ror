class MembershipPayoutJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.first)
  end

  def perform(community_id, user_id)
    community = Community.find(community_id)
    user = Person.find(user_id)
    return unless user.referrer_id.present? && user.signup_charge_id.present?

    affiliate = Person.where(referral_id: user.referrer_id.strip).first
    return unless affiliate

    MailCarrier.deliver_now(PersonMailer.new_referral_signup(community, affiliate, user))

    if affiliate.is_affiliate?
      stripe_account = StripeAccount.where(person_id: affiliate.id).where('stripe_seller_id is not null').first
      return unless stripe_account

      charge = StripeService::API::StripeApiWrapper.get_charge(community: community.id, charge_id: user.signup_charge_id)
      amount = (charge.amount * community.affiliate_percent / 100.0).to_i
      if APP_CONFIG.instant_membership_transfer
        StripeService::API::StripeApiWrapper.perform_simple_transfer(
          community: community_id,
          account_id: stripe_account.stripe_seller_id,
          amount_cents: amount,
          amount_currency: 'USD',
          charge_id:  user.signup_charge_id)
      else
        balance_txn = StripeService::API::StripeApiWrapper.get_platform_balance_txn(community: community.id, balance_txn_id: charge.balance_transaction)
        available_on = Time.zone.at(balance_txn.available_on) + 2.hours
        MembershipTransferJob.set(wait_until: available_on).perform_later(community_id, stripe_account.stripe_seller_id, amount)
      end

    elsif affiliate.premium_active?
      affiliate.membership_expires_at += community.membership_extend.months
      affiliate.save
    end
  end
end
