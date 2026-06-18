class AutomaticallyRejectPreauthorizedTransactionJob < ApplicationJob

  queue_as :transactions

  include SessionContextSerializer
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community.id)
  end

  def perform(conversation_id)
    transaction = Transaction.find(conversation_id)

    if(transaction.current_state == "preauthorized")
      TransactionService::Transaction.reject(community_id: transaction.community_id,
                                             transaction_id: transaction.id, auto: true)
    end
  end

end
