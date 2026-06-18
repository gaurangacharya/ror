class TransactionProcessStateMachine
  include Statesman::Machine

  state :not_started, initial: true
  state :free
  state :initiated
  state :pending  # Deprecated
  state :preauthorized
  state :pending_ext
  state :accepted # Deprecated
  state :rejected
  state :errored
  state :paid
  state :confirmed
  state :canceled

  transition from: :not_started,               to: [:free, :initiated]
  transition from: :initiated,                 to: [:preauthorized, :pending]
  transition from: :preauthorized,             to: [:paid, :rejected, :pending_ext, :errored]
  transition from: :pending,                   to: [:paid, :rejected, :pending_ext, :errored]
  transition from: :pending_ext,               to: [:paid, :rejected]
  transition from: :paid,                      to: [:confirmed, :canceled, :rejected]
  transition from: :confirmed,                 to: [:rejected]
  transition from: :canceled,                  to: [:rejected]

  after_transition do |transaction, transition|
    transaction.update_columns(
      current_state: transition.to_state,
      last_transition_at: Time.current)
  end

  after_transition(to: :paid, after_commit: true) do |transaction|
    payer = transaction.starter
    current_community = transaction.community

    if transaction.booking.present?
      booking = transaction.booking
      automatic_booking_confirmation_at = (booking.per_hour ? booking.end_time : booking.end_on) + 2.days
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_booking_confirmation_at!(automatic_booking_confirmation_at)

    else
      ConfirmConversation.new(transaction, payer, current_community).activate_automatic_confirmation!
    end

    if transaction.listing.author.is_affiliate? && (payer.is_hotel? || payer.is_hotel_guest?) || transaction.referral_id.present?
      HotelCommissionJob.perform_later(transaction.id, transaction.community_id)
    end

    DocusignService.new(transaction).send_documents!
    SendPaymentReceipts.perform_later(transaction.id)
  end

#  after_transition(to: :rejected) do |transaction, transition|
#    rejecter = transaction.listing.author
#    current_community = transaction.community
#
#    TransactionStatusChangedJob.perform_later(transaction.id, rejecter.id, current_community.id, transition.metadata)
#    TwilioSmsJob.set(priority: 9).perform_later(transaction.community_id, transaction.starter_id, I18n.t("twilio.transaction_rejected", rejecter_name: rejecter.full_name, transaction_id: transaction.id))
#    StripeCancelDepositJob.perform_later(transaction.id, current_community.id)
#  end

  after_transition(to: :confirmed) do |conversation|
    confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
    confirmation.confirm!
  end

  after_transition(from: :paid, to: :canceled) do |conversation|
    confirmation = ConfirmConversation.new(conversation, conversation.starter, conversation.community)
    confirmation.cancel!
    TwilioSmsJob.set(priority: 9).perform_later(conversation.community_id, conversation.starter_id, I81n.t("twilio.transaction_canceled", transaction_id: conversation.id))
  end

end
