require 'rails_helper'

RSpec.describe 'Job Enqueueing Migration', type: :job do
  describe 'ActiveJob integration' do
    before do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    describe 'SendWelcomeEmail' do
      let(:person) { create(:person) }
      let(:community) { create(:community) }

      before do
        # Create community membership to avoid nil errors
        create(:community_membership, person: person, community: community, admin: false)
      end

      it 'enqueues job with correct arguments' do
        expect {
          SendWelcomeEmail.perform_later(person.id, community.id)
        }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id)
      end

      it 'performs job correctly' do
        mail_double = double('Mail::Message')
        expect(PersonMailer).to receive(:welcome_email).with(person, community).and_return(mail_double)
        expect(MailCarrier).to receive(:deliver_now).with(mail_double)
        
        SendWelcomeEmail.perform_now(person.id, community.id)
      end
    end

    describe 'MessageSentJob' do
      let(:message) { create(:message) }
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        expect {
          MessageSentJob.perform_later(message.id, community.id)
        }.to have_enqueued_job(MessageSentJob).with(message.id, community.id)
      end

      it 'performs job correctly' do
        allow(Message).to receive(:find).with(message.id).and_return(message)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(message).to receive(:send_email_to_participants).with(community)
        
        MessageSentJob.perform_now(message.id, community.id)
      end
    end

    describe 'CommentCreatedJob' do
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        # Use build to avoid Sphinx issues, only need ID for enqueueing
        comment = build(:comment)
        
        expect {
          CommentCreatedJob.perform_later(comment.id, community.id)
        }.to have_enqueued_job(CommentCreatedJob).with(comment.id, community.id)
      end

      it 'performs job correctly' do
        # Mock comment due to Sphinx connection issues with comment factory
        comment = double('Comment', id: 1)
        
        allow(Comment).to receive(:find).with(comment.id).and_return(comment)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(comment).to receive(:send_notifications).with(community)
        
        CommentCreatedJob.perform_now(comment.id, community.id)
      end
    end

    describe 'ListingCreatedJob' do
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        # Use build to avoid Sphinx issues, only need ID for enqueueing
        listing = build(:listing, community_id: community.id)
        
        expect {
          ListingCreatedJob.perform_later(listing.id, community.id)
        }.to have_enqueued_job(ListingCreatedJob).with(listing.id, community.id)
      end

      it 'performs job correctly when payment settings reminder should be sent' do
        listing = build(:listing, community_id: community.id)
        
        allow(Listing).to receive(:find).with(listing.id).and_return(listing)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        allow(MarketplaceService::Listing::Entity).to receive(:send_payment_settings_reminder?)
          .with(listing.id, community.id).and_return(true)
        
        expect(PersonMailer).to receive(:payment_settings_reminder)
          .with(listing, listing.author, community).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        ListingCreatedJob.perform_now(listing.id, community.id)
      end

      it 'skips email when payment settings reminder should not be sent' do
        listing = build(:listing, community_id: community.id)
        
        allow(Listing).to receive(:find).with(listing.id).and_return(listing)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        allow(MarketplaceService::Listing::Entity).to receive(:send_payment_settings_reminder?)
          .with(listing.id, community.id).and_return(false)
        
        expect(PersonMailer).not_to receive(:payment_settings_reminder)
        expect(MailCarrier).not_to receive(:deliver_now)
        
        ListingCreatedJob.perform_now(listing.id, community.id)
      end
    end

    describe 'InvitationCreatedJob' do
      let(:invitation) { create(:invitation) }
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        expect {
          InvitationCreatedJob.perform_later(invitation.id, community.id)
        }.to have_enqueued_job(InvitationCreatedJob).with(invitation.id, community.id)
      end

      it 'performs job correctly' do
        expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        InvitationCreatedJob.perform_now(invitation.id, community.id)
      end
    end

    describe 'TestimonialGivenJob' do
      let(:receiver) { create(:person) }
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        # Use build to avoid Sphinx issues, only need ID for enqueueing
        testimonial = build(:testimonial, receiver: receiver)
        
        expect {
          TestimonialGivenJob.perform_later(testimonial.id, community.id)
        }.to have_enqueued_job(TestimonialGivenJob).with(testimonial.id, community.id)
      end

      it 'performs job correctly when receiver should receive notifications' do
        # Mock testimonial due to Sphinx connection issues with testimonial factory
        testimonial = double('Testimonial', id: 1, receiver: receiver)
        
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials").and_return(true)
        expect(PersonMailer).to receive(:new_testimonial).with(testimonial, community).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end

      it 'skips email when receiver should not receive notifications' do
        # Mock testimonial due to Sphinx connection issues with testimonial factory
        testimonial = double('Testimonial', id: 1, receiver: receiver)
        
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials").and_return(false)
        expect(PersonMailer).not_to receive(:new_testimonial)
        expect(MailCarrier).not_to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end
    end

    describe 'PageLoadedJob' do
      let(:person) { create(:person) }
      let(:community) { create(:community) }
      let(:community_membership) { create(:community_membership, person: person, community: community) }
      let(:host) { 'example.com' }

      it 'enqueues job with correct arguments' do
        expect {
          PageLoadedJob.perform_later(community_membership.id, host)
        }.to have_enqueued_job(PageLoadedJob).with(community_membership.id, host)
      end

      it 'performs job correctly when last page load date is different' do
        community_membership.update!(last_page_load_date: 1.day.ago)
        
        # Mock the finder and the object to control the behavior
        allow(CommunityMembership).to receive(:find).with(community_membership.id).and_return(community_membership)
        expect(community_membership).to receive(:update_attribute).with(:last_page_load_date, kind_of(DateTime))
        
        PageLoadedJob.perform_now(community_membership.id, host)
      end

      it 'skips update when last page load date is today' do
        community_membership.update!(last_page_load_date: DateTime.now)
        
        # Mock the finder and the object to control the behavior
        allow(CommunityMembership).to receive(:find).with(community_membership.id).and_return(community_membership)
        expect(community_membership).not_to receive(:update_attribute)
        
        PageLoadedJob.perform_now(community_membership.id, host)
      end
    end

    describe 'ReprocessListingImageJob' do
      let(:listing_image) { double('ListingImage', id: 1) }
      let(:style) { 'medium' }

      it 'enqueues job with correct arguments' do
        expect {
          ReprocessListingImageJob.perform_later(listing_image.id, style)
        }.to have_enqueued_job(ReprocessListingImageJob).with(listing_image.id, style)
      end

      it 'performs job correctly' do
        image_double = double('Image')
        allow(ListingImage).to receive(:find_by_id).with(listing_image.id).and_return(listing_image)
        allow(listing_image).to receive(:image).and_return(image_double)
        expect(image_double).to receive(:reprocess_without_delay!).with(:medium)
        
        ReprocessListingImageJob.perform_now(listing_image.id, style)
      end

      it 'handles missing listing image gracefully' do
        allow(ListingImage).to receive(:find_by_id).with(listing_image.id).and_return(nil)
        
        expect {
          ReprocessListingImageJob.perform_now(listing_image.id, style)
        }.not_to raise_error
      end
    end

    describe 'TransactionAutomaticallyConfirmedJob' do
      let(:community) { create(:community) }

      it 'enqueues job with correct arguments' do
        # Use build to avoid Sphinx issues, only need ID for enqueueing
        transaction = build(:transaction, community: community)
        
        expect {
          TransactionAutomaticallyConfirmedJob.perform_later(transaction.id, community.id)
        }.to have_enqueued_job(TransactionAutomaticallyConfirmedJob).with(transaction.id, community.id)
      end

      it 'performs job correctly' do
        transaction = build(:transaction, community: community)
        
        allow(Transaction).to receive(:find).with(transaction.id).and_return(transaction)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(PersonMailer).to receive(:transaction_automatically_confirmed).with(transaction, community).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        TransactionAutomaticallyConfirmedJob.perform_now(transaction.id, community.id)
      end

      it 'handles exceptions gracefully' do
        allow(Transaction).to receive(:find).and_raise(StandardError.new("Test error"))
        
        expect {
          TransactionAutomaticallyConfirmedJob.perform_now(999, community.id)
        }.not_to raise_error
      end
    end

    describe 'job scheduling with options' do
      let(:person) { create(:person) }
      let(:community) { create(:community) }

      before do
        create(:community_membership, person: person, community: community, admin: false)
      end

      it 'supports delayed execution' do
        expect {
          SendWelcomeEmail.set(wait: 1.hour).perform_later(person.id, community.id)
        }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id)
      end

      it 'supports priority setting' do
        expect {
          SendWelcomeEmail.set(priority: 5).perform_later(person.id, community.id)
        }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id)
      end

      it 'supports queue specification' do
        expect {
          SendWelcomeEmail.set(queue: 'mailers').perform_later(person.id, community.id)
        }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id).on_queue('mailers')
      end
    end
  end

  describe 'ApplicationJob base functionality' do
    let(:person) { create(:person) }
    let(:community) { create(:community) }

    before do
      create(:community_membership, person: person, community: community, admin: false)
    end

    it 'includes DelayedSentryNotification' do
      expect(ApplicationJob.included_modules).to include(DelayedSentryNotification)
    end

    it 'sets community service name automatically' do
      allow(PersonMailer).to receive(:welcome_email).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      SendWelcomeEmail.perform_now(person.id, community.id)
    end
  end
end 