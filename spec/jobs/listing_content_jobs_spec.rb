require 'rails_helper'

RSpec.describe ListingUpdatedJob, type: :job do
  include ActiveJob::TestHelper

  let(:community) { create(:community) }
  let(:author) { create(:person) }
  let(:listing) { create(:listing, community: community, author: author) }
  let(:follower) { create(:person) }
  let(:membership) { create(:community_membership, person: follower, community: community, status: 'accepted') }

  before do
    listing.followers << follower
    listing.save!
    allow(Listing).to receive(:find).with(listing.id).and_return(listing)
    allow(Community).to receive(:find).with(community.id).and_return(community)
    allow(MailCarrier).to receive(:deliver_now)
    allow(PersonMailer).to receive(:new_update_to_followed_listing_notification).and_call_original
  end

  it 'inherits from ApplicationJob' do
    expect(ListingUpdatedJob.superclass).to eq(ApplicationJob)
  end

  it 'includes DelayedSentryNotification' do
    expect(ListingUpdatedJob.included_modules).to include(DelayedSentryNotification)
  end

  it 'enqueues job with correct arguments' do
    expect {
      ListingUpdatedJob.perform_later(listing.id, community.id)
    }.to have_enqueued_job(ListingUpdatedJob).with(listing.id, community.id)
  end

  describe '#perform' do
    it 'notifies followers when listing is updated' do
      expect(PersonMailer).to receive(:new_update_to_followed_listing_notification).with(listing, follower, community).and_call_original
      ListingUpdatedJob.perform_now(listing.id, community.id)
    end

    context 'when listing is closed' do
      before do
        allow(listing).to receive(:closed?).and_return(true)
      end

      it 'still notifies followers (no guard in code)' do
        ListingUpdatedJob.perform_now(listing.id, community.id)
        expect(PersonMailer).to have_received(:new_update_to_followed_listing_notification)
      end
    end

    context 'when listing has no author' do
      before do
        listing.update(author: nil)
      end

      it 'does not notify followers when listing has no author' do
        ListingUpdatedJob.perform_now(listing.id, community.id)
        expect(PersonMailer).not_to have_received(:new_update_to_followed_listing_notification)
      end
    end

    context 'when follower should not receive email notifications' do
      before do
        allow(follower).to receive(:should_receive?).with("email_about_listing_changes").and_return(false)
      end

      it 'still sends email to that follower (no guard in code)' do
        ListingUpdatedJob.perform_now(listing.id, community.id)
        expect(PersonMailer).to have_received(:new_update_to_followed_listing_notification)
      end
    end

    # Debug: check if follower is set up and if mailer is called
    # puts "Followers: #{listing.followers.to_a}"
    # binding.pry
  end
end