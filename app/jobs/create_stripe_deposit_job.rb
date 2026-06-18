class CreateStripeDepositJob < ApplicationJob
  include DelayedSentryNotification

  queue_as :transactions

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(transaction_id, community_id)
    community = Community.find(community_id)
    transaction = Transaction.find(transaction_id)
    return if transaction.ignore_deposit?
    return unless transaction.was_paid?

    payer_id = StripeAccount.where(person_id: transaction.starter_id).first.stripe_customer_id
    data = {service_name: community.name(community.locales.first), stripe_customer_id: payer_id}
    tx = TransactionService::Transaction.query transaction_id
    result = StripeService::API::Payments.create_preauth_deposit tx, data

    message =
      if result.success
        Message.new(
          conversation_id: transaction.conversation_id,
          sender_id: transaction.listing_author_id,
          content: "Created deposit preauthorization of " + MoneyViewUtils.to_humanized(transaction.deposit))
      else
        Message.new(
          conversation_id: transaction.conversation_id,
          sender_id: transaction.listing_author_id,
          content: "Failed to preauthorize deposit of " + MoneyViewUtils.to_humanized(transaction.deposit))
      end
    message.save
    MessageSentJob.perform_later(message.id, community_id)

  end
end
