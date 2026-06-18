class StripeCancelDepositJob < ApplicationJob

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(transaction_id, community_id)
    tx = TransactionService::Transaction.query transaction_id
    result = StripeService::API::Api.payments.cancel_deposit(tx, nil)
    if result.success
      unless result.data.is_a?(String)
        tx_model = ::Transaction.find(transaction_id)
        message = Message.new(
          conversation_id: tx_model.conversation_id,
          sender_id: tx_model.listing_author_id,
          content: "Automatically refunded deposit of " + MoneyViewUtils.to_humanized(result.data[:refund_amount]))
        message.save
        MessageSentJob.perform_later(message.id, community_id)
      end
    end
  end
end
