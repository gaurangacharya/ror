class TransactionConfirmedJob < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(conversation_id, community_id)
    transaction = Transaction.find(conversation_id)
    community = Community.find(community_id)
    author = transaction.author

    #if author&.should_receive?("email_about_completed_transactions")
    #  MailCarrier.deliver_now(PersonMailer.transaction_confirmed(transaction, community))
    #end

    if transaction.payment_gateway == "stripe"
      payment = StripeService::Store::StripePayment.get(community_id, transaction.id)
      default_available = APP_CONFIG.stripe_payout_delay.to_f.days.from_now
      available_date = (payment[:available_on] || default_available) + 24.hours
      case StripeService::API::Api.wrapper.charges_mode(community_id)
      when :destination, :direct then StripePayoutJob.set(priority: 9, wait_until: available_date).perform_later(transaction.id, community_id)
      when :separate then StripePayoutJob.set(priority: 9).perform_later(transaction.id, community_id)
      end
    end
  end
end
