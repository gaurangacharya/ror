#require 'factory_bot'

class MailPreview < MailView
  include MailViewTestData

  def payment_settings_reminder
    PersonMailer.payment_settings_reminder(listing, member, community)
  end

  def paypal_receipt_to_payer
    transaction = TransactionService::DataTypes::Transaction.create_transaction({
        id: 999,
        payment_process: :preauthorize,
        payment_gateway: :paypal,
        community_id: 999,
        starter_id: paypal_transaction.starter.id,
        listing_id: paypal_transaction.listing.id,
        listing_title: paypal_transaction.listing.title,
        listing_price: paypal_transaction.listing.price,
        shipping_price: paypal_transaction.shipping_price,
        listing_author_id: paypal_transaction.listing.author.id,
        listing_quantity: 1,
        last_transition_at: Time.now,
        current_state: :paid,
        payment_total: Money.new(2000, "USD")
      })

    seller_model = paypal_transaction.listing.author
    buyer_model = paypal_transaction.starter
    community = paypal_transaction.community

    TransactionMailer.paypal_receipt_to_payer(transaction, seller_model, buyer_model, community)
  end

  def paypal_new_payment
    transaction = TransactionService::DataTypes::Transaction.create_transaction({
        id: 999,
        payment_process: :preauthorize,
        payment_gateway: :paypal,
        community_id: 999,
        starter_id: paypal_transaction.starter.id,
        listing_id: paypal_transaction.listing.id,
        listing_title: paypal_transaction.listing.title,
        listing_price: paypal_transaction.listing.price,
        shipping_price: paypal_transaction.shipping_price,
        listing_author_id: paypal_transaction.listing.author.id,
        listing_quantity: 1,
        last_transition_at: Time.now,
        current_state: :paid,
        payment_total: Money.new(2000, "USD"),
        charged_commission: Money.new(200, "USD"),
        payment_gateway_fee: Money.new(85, "USD")
      })

    seller_model = paypal_transaction.listing.author
    buyer_model = paypal_transaction.starter
    community = paypal_transaction.community

    TransactionMailer.paypal_new_payment(transaction, seller_model, buyer_model, community)
  end

  def white_label_payment_receipt_to_buyer
    transaction_hash = create_white_label_transaction_hash
    seller_model = create_white_label_seller
    buyer_model = create_test_buyer
    community_model = community

    TransactionMailer.payment_receipt_to_buyer(transaction_hash, seller_model, buyer_model, community_model)
  end

  def white_label_payment_receipt_to_seller
    transaction_hash = create_white_label_transaction_hash
    seller_model = create_white_label_seller
    buyer_model = create_test_buyer
    community_model = community

    TransactionMailer.payment_receipt_to_seller(transaction_hash, seller_model, buyer_model, community_model)
  end

  def confirm_reminder
    PersonMailer.confirm_reminder(conversation, conversation.buyer, conversation.community, 4)
  end

  def transaction_confirmed
    PersonMailer.transaction_confirmed(conversation, community)
  end

  def transaction_automatically_confirmed
    PersonMailer.transaction_automatically_confirmed(conversation, community)
  end

  def booking_transaction_automatically_confirmed
    conversation = Conversation.last
    community = conversation.community
    # conversation.status = "confirmed"
    PersonMailer.booking_transaction_automatically_confirmed(conversation, community)
  end

  def community_updates
    CommunityMailer.community_updates(member, community, [listing])
  end

  def welcome_email
    PersonMailer.welcome_email(member, community)
  end

  def transaction_preauthorized
    change_conversation_status_to!("preauthorized")
    TransactionMailer.transaction_preauthorized(transaction)
  end

  def transaction_preauthorized_reminder
    change_conversation_status_to!("preauthorized")
    TransactionMailer.transaction_preauthorized_reminder(transaction)
  end

  def new_listing_by_followed_person
    PersonMailer.new_listing_by_followed_person(listing, member, community)
  end

  private

  # Private methods to make modifications to default test data

  def change_conversation_status_to!(status)
    transaction.transaction_transitions << FactoryBot.build(:transaction_transition, to_state: status)
  end

  def create_white_label_transaction_hash
    {
      id: 999,
      community_id: community.id,
      listing_author_id: "white_label_seller",
      starter_id: "test_buyer",
      listing_title: "Ladera Adventure Tour",
      payment_total: Money.new(15000, "USD"), # $150
      item_total: Money.new(15000, "USD"),
      listing_quantity: 2,
      payment_gateway: :stripe,
      listing_price: Money.new(7500, "USD"), # $75 per person
      booking: { duration: 3 }
    }
  end

  def create_white_label_seller
    seller = Person.new(
      id: "white_label_seller",
      given_name: "Ladera",
      family_name: "Adventures",
      locale: "en"
    )
    
    # Create white label configuration
    white_label = PersonWhiteLabel.new(
      person: seller,
      design: "ladera",
      domain: "ladera-adventures.com",
      custom_color1: "4a90e2",
      custom_color2: "2ab865"
    )
    
    # Associate white label with seller
    seller.define_singleton_method(:person_white_label) { white_label }
    seller.define_singleton_method(:confirmed_notification_emails_to) { ["seller@ladera-adventures.com"] }
    
    seller
  end

  def create_test_buyer
    buyer = Person.new(
      id: "test_buyer",
      given_name: "John",
      family_name: "Customer",
      locale: "en"
    )
    
    buyer.define_singleton_method(:confirmed_notification_emails_to) { ["customer@example.com"] }
    buyer.define_singleton_method(:guest?) { false }
    
    buyer
  end
end
