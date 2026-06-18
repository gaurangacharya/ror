require 'rails_helper'

RSpec.describe 'Transaction and Payment Jobs', type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  describe 'TransactionPreauthorizedJob' do
    let(:community) { create(:community) }
    let(:transaction) { create(:transaction, community: community) }

    it 'enqueues job with correct arguments' do
      expect {
        TransactionPreauthorizedJob.perform_later(transaction.id)
      }.to have_enqueued_job(TransactionPreauthorizedJob).with(transaction.id)
    end

    it 'performs job correctly when transaction should send email' do
      transaction.update!(auto_confirm: false)
      expect(TransactionMailer).to receive(:transaction_preauthorized).with(transaction).and_return(double(deliver_now: true))
      expect(MailCarrier).to receive(:deliver_now)
      
      TransactionPreauthorizedJob.perform_now(transaction.id)
    end

    it 'skips email when transaction has auto_confirm enabled' do
      transaction.update!(auto_confirm: true)
      expect(TransactionMailer).not_to receive(:transaction_preauthorized)
      expect(MailCarrier).not_to receive(:deliver_now)
      
      TransactionPreauthorizedJob.perform_now(transaction.id)
    end

    it 'supports priority setting' do
      expect {
        TransactionPreauthorizedJob.set(priority: 5).perform_later(transaction.id)
      }.to have_enqueued_job(TransactionPreauthorizedJob).with(transaction.id)
    end
  end

  describe 'TransactionConfirmedJob' do
    let(:community) { create(:community) }
    let(:author) { create(:person) }
    let(:listing) { create(:listing, author: author, community: community) }
    let(:transaction) { create(:transaction, listing: listing, community: community, payment_gateway: 'paypal') }

    it 'enqueues job with correct arguments' do
      expect {
        TransactionConfirmedJob.perform_later(transaction.id, community.id)
      }.to have_enqueued_job(TransactionConfirmedJob).with(transaction.id, community.id)
    end

    it 'performs job correctly for non-stripe payment' do
      # No need to mock Transaction.find or Community.find since we have real records
      # No need to mock payment_gateway since it's set in the factory
      # No need to mock store_community_service_name_to_thread_from_community_id since it's handled by before_perform
      
      TransactionConfirmedJob.perform_now(transaction.id, community.id)
    end

    it 'schedules stripe payout for stripe payments with destination mode' do
      transaction.update!(payment_gateway: 'stripe')
      
      # Mock stripe payment and API since we can't use real Stripe in tests
      payment = { available_on: 2.days.from_now }
      allow(StripeService::Store::StripePayment).to receive(:get).with(community.id, transaction.id).and_return(payment)
      
      stripe_api_wrapper = double('StripeApiWrapper')
      allow(StripeService::API::Api).to receive(:wrapper).and_return(stripe_api_wrapper)
      allow(stripe_api_wrapper).to receive(:charges_mode).with(community.id).and_return(:destination)
      
      expect(StripePayoutJob).to receive(:set).with(priority: 9, wait_until: kind_of(Time)).and_return(StripePayoutJob)
      expect(StripePayoutJob).to receive(:perform_later).with(transaction.id, community.id)
      
      TransactionConfirmedJob.perform_now(transaction.id, community.id)
    end

    it 'schedules immediate stripe payout for separate mode' do
      transaction.update!(payment_gateway: 'stripe')
      
      payment = { available_on: 2.days.from_now }
      allow(StripeService::Store::StripePayment).to receive(:get).with(community.id, transaction.id).and_return(payment)
      
      stripe_api_wrapper = double('StripeApiWrapper')
      allow(StripeService::API::Api).to receive(:wrapper).and_return(stripe_api_wrapper)
      allow(stripe_api_wrapper).to receive(:charges_mode).with(community.id).and_return(:separate)
      
      expect(StripePayoutJob).to receive(:set).with(priority: 9).and_return(StripePayoutJob)
      expect(StripePayoutJob).to receive(:perform_later).with(transaction.id, community.id)
      
      TransactionConfirmedJob.perform_now(transaction.id, community.id)
    end
  end

  describe 'TransactionCanceledJob' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:starter) { create(:person) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        starter: starter,
        current_state: 'canceled'
      )
    end

    it 'enqueues job with correct arguments' do
      expect {
        TransactionCanceledJob.perform_later(transaction.id, community.id)
      }.to have_enqueued_job(TransactionCanceledJob).with(transaction.id, community.id)
    end

    it 'performs job correctly' do
      expect(PersonMailer).to receive(:transaction_confirmed).with(transaction, community).and_return(double(deliver_now: true))
      
      TransactionCanceledJob.perform_now(transaction.id, community.id)
    end

    it 'handles missing transaction gracefully' do
      non_existent_id = 999999
      
      expect {
        TransactionCanceledJob.perform_now(non_existent_id, community.id)
      }.not_to raise_error
    end
  end

  describe 'TransactionAutomaticallyConfirmedJob' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:starter) { create(:person) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        starter: starter,
        current_state: 'confirmed'
      )
    end

    it 'enqueues job with correct arguments' do
      expect {
        TransactionAutomaticallyConfirmedJob.perform_later(transaction.id, community.id)
      }.to have_enqueued_job(TransactionAutomaticallyConfirmedJob).with(transaction.id, community.id)
    end

    it 'performs job correctly' do
      expect(PersonMailer).to receive(:transaction_automatically_confirmed).with(transaction, community).and_return(double(deliver_now: true))
      
      TransactionAutomaticallyConfirmedJob.perform_now(transaction.id, community.id)
    end
  end

  describe 'AutomaticallyRejectPreauthorizedTransactionJob' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:starter) { create(:person) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        starter: starter,
        current_state: 'preauthorized'
      )
    end

    it 'enqueues job with correct arguments' do
      expect {
        AutomaticallyRejectPreauthorizedTransactionJob.perform_later(transaction.id)
      }.to have_enqueued_job(AutomaticallyRejectPreauthorizedTransactionJob).with(transaction.id)
    end

    it 'performs job correctly when transaction is preauthorized' do      
      expect(TransactionService::Transaction).to receive(:reject)
        .with(community_id: community.id, transaction_id: transaction.id, auto: true)
        .and_return(Result::Success.new({}))
      
      AutomaticallyRejectPreauthorizedTransactionJob.perform_now(transaction.id)
    end
  end

  describe 'TransactionStatusChangedJob' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:starter) { create(:person) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        starter: starter,
        current_state: 'rejected'
      )
    end

    it 'enqueues job with correct arguments' do
      expect {
        TransactionStatusChangedJob.perform_later(transaction.id)
      }.to have_enqueued_job(TransactionStatusChangedJob).with(transaction.id)
    end

    it 'performs job correctly' do
      # Use factories for all real entities
      community = create(:community)
      starter = create(:person)
      author = create(:person)
      listing = create(:listing, community: community, author: author)
      transaction = create(:transaction, community: community, listing: listing, starter: starter, current_state: 'rejected')
      metadata = {}

      # The job expects: (conversation_id, current_user_id, community_id, metadata)
      # We'll use starter as the current_user, so author is the other_party
      allow(author).to receive(:should_receive?).with("email_when_conversation_rejected").and_return(true)
      allow(author).to receive(:guest?).and_return(false)

      mailer_double = double('Mailer')
      expect(PersonMailer).to receive(:conversation_status_changed)
        .with(transaction, community, metadata)
        .and_return(mailer_double)
      expect(MailCarrier).to receive(:deliver_now).with(mailer_double)

      TransactionStatusChangedJob.perform_now(transaction.id, starter.id, community.id, metadata)
    end
  end

  describe 'job scheduling and integration' do
    let(:community) { create(:community) }
    let(:transaction) { build(:transaction, community: community) }

    it 'supports delayed execution for transaction jobs' do
      expect {
        TransactionPreauthorizedJob.set(wait: 1.hour).perform_later(transaction.id)
      }.to have_enqueued_job(TransactionPreauthorizedJob).with(transaction.id)
    end

    it 'supports priority setting for transaction jobs' do
      expect {
        TransactionConfirmedJob.set(priority: 5).perform_later(transaction.id, community.id)
      }.to have_enqueued_job(TransactionConfirmedJob).with(transaction.id, community.id)
    end

    it 'supports queue specification for transaction jobs' do
      expect {
        TransactionAutomaticallyConfirmedJob.set(queue: 'transactions').perform_later(transaction.id, community.id)
      }.to have_enqueued_job(TransactionAutomaticallyConfirmedJob).with(transaction.id, community.id).on_queue('transactions')
    end
  end

  describe 'ApplicationJob inheritance and functionality' do
    let(:community) { create(:community) }
    let(:transaction) { create(:transaction, community: community) }

    it 'includes DelayedSentryNotification for error handling' do
      expect(TransactionConfirmedJob.included_modules).to include(DelayedSentryNotification)
      expect(TransactionCanceledJob.included_modules).to include(DelayedSentryNotification)
      expect(TransactionStatusChangedJob.included_modules).to include(DelayedSentryNotification)
      expect(AutomaticallyRejectPreauthorizedTransactionJob.included_modules).to include(DelayedSentryNotification)
    end

    it 'inherits from ApplicationJob' do
      expect(TransactionPreauthorizedJob.superclass).to eq(ApplicationJob)
      expect(TransactionConfirmedJob.superclass).to eq(ApplicationJob)
      expect(TransactionAutomaticallyConfirmedJob.superclass).to eq(ApplicationJob)
      expect(TransactionCanceledJob.superclass).to eq(ApplicationJob)
      expect(TransactionStatusChangedJob.superclass).to eq(ApplicationJob)
      expect(AutomaticallyRejectPreauthorizedTransactionJob.superclass).to eq(ApplicationJob)
    end
  end

  describe 'payment flow integration' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        current_state: 'preauthorized'
      )
    end

    it 'handles complete payment flow from preauthorization to confirmation' do
      # Test the typical flow: preauthorized -> confirmed
      allow(transaction).to receive(:auto_confirm?).and_return(false)
      expect(TransactionMailer).to receive(:transaction_preauthorized).with(transaction).and_return(double(deliver_now: true))
      expect(MailCarrier).to receive(:deliver_now)
      
      TransactionPreauthorizedJob.perform_now(transaction.id)
      
      # Step 2: Confirmation
      allow(transaction).to receive(:payment_gateway).and_return('paypal')
      
      TransactionConfirmedJob.perform_now(transaction.id, community.id)
    end

    it 'handles automatic rejection flow' do
      expect(TransactionService::Transaction).to receive(:reject).with(
        community_id: community.id,
        transaction_id: transaction.id,
        auto: true
      )
      
      AutomaticallyRejectPreauthorizedTransactionJob.perform_now(transaction.id)
    end
  end

  describe 'error handling and edge cases' do
    let(:community) { create(:community) }
    let(:listing) { create(:listing, community: community) }
    let(:starter) { create(:person) }
    let(:transaction) do
      create(:transaction,
        community: community,
        listing: listing,
        starter: starter,
        current_state: 'rejected'
      )
    end

    it 'handles missing transaction gracefully' do
      non_existent_id = 999999
      
      expect {
        TransactionCanceledJob.perform_now(non_existent_id, community.id)
      }.not_to raise_error
      
      expect {
        TransactionAutomaticallyConfirmedJob.perform_now(non_existent_id, community.id)
      }.not_to raise_error
    end

    it 'handles missing community gracefully' do
      non_existent_id = 999999
      
      expect {
        TransactionCanceledJob.perform_now(transaction.id, non_existent_id)
      }.not_to raise_error
      
      expect {
        TransactionAutomaticallyConfirmedJob.perform_now(transaction.id, non_existent_id)
      }.not_to raise_error
    end

    it 'handles mailer failures gracefully' do
      expect(PersonMailer).to receive(:transaction_confirmed).and_raise(StandardError, 'Mailer error')
      
      expect {
        TransactionCanceledJob.perform_now(transaction.id, community.id)
      }.not_to raise_error
    end
  end

  describe 'job inheritance' do
    it 'inherits from ApplicationJob' do
      expect(TransactionCanceledJob.superclass).to eq(ApplicationJob)
      expect(TransactionAutomaticallyConfirmedJob.superclass).to eq(ApplicationJob)
      expect(AutomaticallyRejectPreauthorizedTransactionJob.superclass).to eq(ApplicationJob)
      expect(TransactionStatusChangedJob.superclass).to eq(ApplicationJob)
    end
  end
end 