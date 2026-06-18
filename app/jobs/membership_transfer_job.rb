class MembershipTransferJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.first)
  end

  def perform(community_id, seller_id, amount)
    StripeService::API::StripeApiWrapper.perform_simple_transfer(
      community: community_id,
      account_id: seller_id,
      amount_cents: amount,
      amount_currency: 'USD',
      charge_id: nil)
  end
end
