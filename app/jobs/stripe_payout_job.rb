class StripePayoutJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(transaction_id, community_id)
    tx = TransactionService::Transaction.query transaction_id
    StripeService::API::Api.payments.payout(tx)
  end
end
