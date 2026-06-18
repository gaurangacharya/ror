class TransactionPreauthorizedReminderJob < ApplicationJob

  queue_as :transactions

  include SessionContextSerializer
  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    transaction = Transaction.find(job.arguments.first)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(transaction.community.id)
  end

  def perform(transaction_id)
    transaction = Transaction.find(transaction_id)

    return if Maybe(::PlanService::API::Api.plans.get_current(community_id: transaction.community.id).data)[:expired].or_else(false)

    if transaction.status == "preauthorized"
      MailCarrier.deliver_now(TransactionMailer.transaction_preauthorized_reminder(transaction))
    end
  end
end
