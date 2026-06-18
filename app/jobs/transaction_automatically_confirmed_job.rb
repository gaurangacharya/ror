class TransactionAutomaticallyConfirmedJob < ApplicationJob
  queue_as :transactions

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(conversation_id, community_id)
    begin
      transaction = Transaction.find(conversation_id)
      community = Community.find(community_id)
      MailCarrier.deliver_now(PersonMailer.transaction_automatically_confirmed(transaction, community))
    rescue => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  end

end
