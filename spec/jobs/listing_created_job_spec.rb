require 'rails_helper'

RSpec.describe ListingCreatedJob, type: :job do
  include ActiveJob::TestHelper

  let(:community) { create(:community) }
  let(:person) { create(:person) }
  let(:listing) { create(:listing, community: community, author: person) }

  before do
    # Create community customizations
    create(:community_customization, community: community)
    
    # Create community membership
    create(:community_membership, person: person, community: community, status: 'accepted')
    
    # Create confirmed email for notifications
    create(:email, person: person, community_id: community.id, address: "author@example.com", confirmed_at: Time.now)
  end

  describe '#perform' do
    context 'when payment settings reminder is needed' do
      before do
        allow(MarketplaceService::Listing::Entity).to receive(:send_payment_settings_reminder?)
          .with(listing.id, community.id)
          .and_return(true)
      end

      it 'sends payment settings reminder email' do
        expect(MailCarrier).to receive(:deliver_now).with(instance_of(ActionMailer::MessageDelivery))
        described_class.perform_now(listing.id, community.id)
      end
    end

    context 'when payment settings reminder is not needed' do
      before do
        allow(MarketplaceService::Listing::Entity).to receive(:send_payment_settings_reminder?)
          .with(listing.id, community.id)
          .and_return(false)
      end

      it 'does not send payment settings reminder email' do
        expect(MailCarrier).not_to receive(:deliver_now)
        described_class.perform_now(listing.id, community.id)
      end
    end

    context 'when listing does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          ListingCreatedJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          ListingCreatedJob.new.perform(listing.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(ListingCreatedJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(ListingCreatedJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end 