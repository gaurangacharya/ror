require 'rails_helper'

RSpec.describe ListingUpdatedJob, type: :job do
  include ActiveJob::TestHelper

  let(:community) { create(:community) }
  let(:person) { create(:person) }
  let(:listing) { create(:listing, community: community, author: person, open: true, valid_until: 3.months.from_now) }
  let(:follower) { create(:person) }

  before do
    # Create community customizations
    create(:community_customization, community: community)
    
    # Create community memberships
    create(:community_membership, person: person, community: community, status: 'accepted')
    create(:community_membership, person: follower, community: community, status: 'accepted')
    
    # Create confirmed emails for notifications
    create(:email, person: person, community_id: community.id, address: "author@example.com", confirmed_at: Time.current, send_notifications: true)
    create(:email, person: follower, community_id: community.id, address: "follower@example.com", confirmed_at: Time.current, send_notifications: true)
    
    # Add follower to the listing
    listing.followers << follower
  end

  describe '#perform' do
    it 'notifies followers when listing is updated' do
      expect_any_instance_of(Listing).to receive(:notify_followers).with(community, listing.author, true)
      ListingUpdatedJob.perform_now(listing.id, community.id)
    end

    context 'when listing is closed' do
      before do
        listing.update(open: false)
      end

      it 'does not notify followers' do
        expect_any_instance_of(Listing).not_to receive(:notify_followers).at_least(:once)
        ListingUpdatedJob.perform_now(listing.id, community.id)
      end
    end

    context 'when listing has no author' do
      before do
        # Properly nullify the author association
        listing.update_column(:author_id, nil)
        listing.reload
      end

      it 'does not notify followers' do
        expect_any_instance_of(Listing).not_to receive(:notify_followers).at_least(:once)
        ListingUpdatedJob.perform_now(listing.id, community.id)
      end
    end
  end
end 