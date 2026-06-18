class InboxPresenter
  PER_PAGE = 30
  attr_reader :current_person, :params, :community, :person_white_label

  def initialize(current_person:, params:, community:, person_white_label:)
    @current_person = current_person
    @params = params
    @community = community
    @person_white_label = person_white_label
  end

  def count
    default_scope.distinct.count
  end

  def index
    decorate(index_scope.paginate(page: params[:page], per_page: PER_PAGE))
  end

  def decorate(collection)
    collection.records.each do |conversation|
      conversation.extend ConversationDecorator
      conversation.current_person = current_person
      conversation
    end
    collection
  end

  def index_scope
    scope = default_scope
    .includes(tx: [:listing, :testimonials, :transaction_transitions])
    .select('
      conversations.*,
      GREATEST(COALESCE(transactions.last_transition_at, 0),
        COALESCE(conversations.last_message_at, 0))     AS last_activity_at
    ')

    if (filter.group_by_username)
      scope = scope.order('transactions.starter_id': :asc, last_activity_at: :desc)
    else
      scope = scope.order(last_activity_at: :desc)
    end

    scope
  end

  def csv_scope
    index_scope.where.not(transactions: {id: nil})
  end

  def default_scope
    Conversation.for_person(current_person).with_tx
  end

  def filter
    @filter ||= Filter.new(filter_params)
  end

  def filter_params
    params[:f] && params[:f].permit!
  end

  def generate_csv
    @generate_csv ||= ExportCsv.new(conversations: decorate(csv_scope.all), full_domain: full_domain).generate
  end

  def full_domain
    if person_white_label
      person_white_label.full_domain
    else
      community.full_url
    end
  end

  module ConversationDecorator
    attr_accessor :current_person

    def title
      if message = messages.first
        message.content
      elsif tx.present?
        action_messages = TransactionViewUtils.create_messages_from_actions(
          tx.transaction_transitions.most_recent,
          tx.listing.author.attributes.deep_symbolize_keys,
          tx.starter.attributes.deep_symbolize_keys,
          tx.total,
          tx.deposit,
        )
        action_messages.last[:content]
      end
    end

    def other
      @other ||= other_party(current_person)
    end

    def should_notify
      current_participation.is_read
    end

    def current_participation
      participation_for(current_person)
    end

    def is_starter
      current_participation.is_starter
    end

    def other_avatar
      person_avatar(other)
    end

    def person_avatar(person)
      person.image.present? ? person.image.url(:thumb) : ActionController::Base.helpers.image_path("profile_image/thumb/missing.png")
    end

    def listing
      tx&.listing
    end

    def last_transition_to_state
      tx&.current_state
    end

    def last_transition_status_meta
      most_recent_transaction_transition&.metadata
    end

    def most_recent_transaction_transition
      tx.transaction_transitions.most_recent.first
    end

    def waiting_feedback
      return false if tx.author.reviews_disabled?

      tx.current_state = 'confirmed' && tx.testimonials.empty? && (
        (current_participation.is_starter && !tx.starter_skipped_feedback) ||
        (!current_participation.is_starter && !tx.author_skipped_feedback)
      )
    end

    def path
      if tx.present?
        Rails.application.routes.url_helpers.person_transaction_path(person_id: current_person.username, id: tx.id)
      else
        Rails.application.routes.url_helpers.single_conversation_path(person_id: current_person.username, conversation_type: "received", id: id)
      end
    end
  end

  class Filter
    include ActiveModel::Model
    include ActiveModel::Attributes
    attribute :group_by_username, :boolean, default: false
  end

  class ExportCsv
    attr_reader :conversations, :full_domain

    def initialize(conversations:, full_domain:)
      @conversations = conversations
      @full_domain = full_domain
    end

    def generate
      Enumerator.new do |yielder|
        first_row_column_names(yielder)
        rows(yielder)
      end
    end

    def first_row_column_names(yielder)
      yielder << [
        'transaction id',
        'status',
        'listing id',
        'listing title',
        'listing Meeting/Pickup Location',
        'listing description',
        'listing image',

        'start date',
        'start time',
        'end time',
        'duration',

        'currency',
        'payment total',
        'unit price',

        'started at',
        'last activity at',
        'starter username',
        'first name',
        'last name',
        'email',
        'hotel guest or visitor',
        'refund amount'
      ].to_csv(force_quotes: true)
    end

    def rows(yielder)
      conversations.each do |conversation|
        yielder << row(conversation).to_csv(force_quotes: true)
      end
    end

    def row(conversation)
      tx = conversation.tx
      listing = tx&.listing
      booking = tx&.booking
      starter = tx&.starter

      unit_price = tx&.unit_price
      payment_total = tx&.total_cents && (tx&.total_cents / 100).round(2)
      start_date = booking&.start_time && I18n.l(booking.start_time, format: :to_datepicker)
      start_time = booking&.start_time && I18n.l(booking.start_time, format: :hours_only)
      end_time = booking&.end_time && I18n.l(booking.end_time, format: :hours_only)

      starter_email = if starter&.email
        starter.email.split('/').last
      else
        starter && starter.emails.confirmed.first&.address
      end

      listing_description = listing && "#{listing.description} #{listing.description_from_provider} #{listing.description_closing}"
      image = listing&.listing_images&.first
      listing_image = image && "#{full_domain}#{image&.image&.url(:square_2x)}"
      
      # Determine if the person is a hotel guest or visitor
      guest_type = if starter&.hotel_guest
        "Hotel Guest"
      else
        "Visitor"
      end
      
      # Get refund information
      refund_amount = "N/A"
      
      if tx.present?
        payment = case tx.payment_gateway
                  when "paypal" then tx.paypal_payment
                  when "stripe" then tx.stripe_payment
                  end
        
        if payment.present?
          refund_cents = payment.respond_to?(:refund_total_cents) ? payment.refund_total_cents : payment.refund_amount_cents
          
          if refund_cents.present?
            refund_amount = MoneyViewUtils.to_humanized(Money.new(refund_cents, payment.currency))
          end
        end
      end

      [
        conversation.id,
        tx&.current_state,
        listing&.id || "N/A",
        listing&.title || "N/A",
        listing&.origin_loc&.address || "N/A",
        listing_description || "N/A",
        listing_image || "N/A",

        start_date,
        start_time,
        end_time,
        booking&.duration,

        unit_price.is_a?(Money) ? unit_price.currency : "N/A",
        payment_total || "N/A",
        unit_price.is_a?(Money) ? unit_price : "N/A",

        conversation&.created_at,
        conversation.last_activity_at,
        starter&.username || "DELETED",
        starter&.given_name || "DELETED",
        starter&.family_name || "DELETED",
        starter_email || "N/A",
        guest_type,
        refund_amount
      ]
    end
  end
end
