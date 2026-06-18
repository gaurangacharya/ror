class DocumentAddedJob < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(transaction_id, sender_id, community_id, document_id)
    transaction = Transaction.find(transaction_id)
    community = Community.find(community_id)
    sender = Person.find(sender_id)
    document = Document.find(document_id)
    MailCarrier.deliver_now(PersonMailer.document_added_to_transaction(transaction, sender, community, document))
  end
end
