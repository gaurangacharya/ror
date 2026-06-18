require 'rails_helper'

RSpec.describe MembershipCancelledJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Use factories for test data - follow cursor rules
  let(:person) { create(:person) }
  let(:community) { create(:community) }
  let(:admin1) { create(:person) }
  let(:admin2) { create(:person) }

  before do
    # Create actual admin memberships instead of mocking
    create(:community_membership, person: admin1, community: community, admin: true)
    create(:community_membership, person: admin2, community: community, admin: true)
    
    # Create confirmed emails for admins so they can receive notifications
    create(:email, person: admin1, address: "admin1@example.com", confirmed_at: Time.current)
    create(:email, person: admin2, address: "admin2@example.com", confirmed_at: Time.current)
  end

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        MembershipCancelledJob.perform_later(person.id, community.id)
      }.to have_enqueued_job(MembershipCancelledJob).with(person.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        MembershipCancelledJob.set(wait: 30.minutes, priority: 3).perform_later(person.id, community.id)
      }.to have_enqueued_job(MembershipCancelledJob).with(person.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        MembershipCancelledJob.set(queue: 'mailers').perform_later(person.id, community.id)
      }.to have_enqueued_job(MembershipCancelledJob).with(person.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    it 'performs job correctly' do
      expect(PersonMailer).to receive(:membership_cancelled).with(person, community).and_return(double(deliver_now: true))
      expect(PersonMailer).to receive(:membership_cancelled_admin).with(admin1, person, community).and_return(double(deliver_now: true))
      expect(PersonMailer).to receive(:membership_cancelled_admin).with(admin2, person, community).and_return(double(deliver_now: true))
      expect(MailCarrier).to receive(:deliver_now).exactly(3).times
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    it 'finds person and community by ID' do
      expect(Person).to receive(:find).with(person.id).and_return(person)
      expect(Community).to receive(:find).with(community.id).and_return(community)
      allow(PersonMailer).to receive(:membership_cancelled).and_return(double(deliver_now: true))
      allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    it 'sends cancellation email to the user' do
      expect(PersonMailer).to receive(:membership_cancelled).with(person, community).and_return(double(deliver_now: true))
      allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    it 'sends notification emails to all admins with confirmed emails' do
      expect(PersonMailer).to receive(:membership_cancelled_admin).with(admin1, person, community).and_return(double(deliver_now: true))
      expect(PersonMailer).to receive(:membership_cancelled_admin).with(admin2, person, community).and_return(double(deliver_now: true))
      allow(PersonMailer).to receive(:membership_cancelled).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    it 'sets community service name correctly' do
      allow(PersonMailer).to receive(:membership_cancelled).and_return(double(deliver_now: true))
      allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    context 'when person does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          MembershipCancelledJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          MembershipCancelledJob.new.perform(person.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'admin notification logic' do
    context 'when admin has confirmed notification email' do
      it 'sends notification to admin' do
        expect(PersonMailer).to receive(:membership_cancelled_admin).with(admin1, person, community)
        allow(PersonMailer).to receive(:membership_cancelled).and_return(double(deliver_now: true))
        allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double(deliver_now: true))
        allow(MailCarrier).to receive(:deliver_now)
        
        MembershipCancelledJob.perform_now(person.id, community.id)
      end
    end

    context 'when admin has no confirmed notification email' do
      let(:community_no_admin_emails) { create(:community) }
      let(:admin_no_email) { create(:person) }
      
      before do
        # Create admin without confirmed email in a separate community
        create(:community_membership, person: admin_no_email, community: community_no_admin_emails, admin: true)
        # Ensure the admin has no confirmed emails
        admin_no_email.emails.destroy_all
      end

      it 'skips notification for admins without confirmed emails' do
        # Should only send user email, no admin emails since no admins have confirmed emails
        expect(PersonMailer).to receive(:membership_cancelled).with(person, community_no_admin_emails).and_return(double(deliver_now: true))
        expect(PersonMailer).not_to receive(:membership_cancelled_admin)
        expect(MailCarrier).to receive(:deliver_now).once # Only user email
        
        MembershipCancelledJob.perform_now(person.id, community_no_admin_emails.id)
      end

      it 'still sends user cancellation email' do
        expect(PersonMailer).to receive(:membership_cancelled).with(person, community_no_admin_emails).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now).once
        
        MembershipCancelledJob.perform_now(person.id, community_no_admin_emails.id)
      end
    end

    context 'when community has no admins' do
      before do
        # Remove admin memberships
        community.community_memberships.where(admin: true).destroy_all
      end

      it 'still sends user cancellation email' do
        expect(PersonMailer).to receive(:membership_cancelled).with(person, community).and_return(double(deliver_now: true))
        expect(PersonMailer).not_to receive(:membership_cancelled_admin)
        expect(MailCarrier).to receive(:deliver_now).once
        
        MembershipCancelledJob.perform_now(person.id, community.id)
      end
    end
  end

  describe 'email delivery workflow' do
    it 'delivers all emails through MailCarrier' do
      allow(PersonMailer).to receive(:membership_cancelled).and_return(double('user_email'))
      allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double('admin_email'))
      
      # Should deliver user email + 2 admin emails = 3 total
      expect(MailCarrier).to receive(:deliver_now).exactly(3).times
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end

    it 'processes admin notifications in sequence' do
      allow(PersonMailer).to receive(:membership_cancelled).and_return(double(deliver_now: true))
      allow(PersonMailer).to receive(:membership_cancelled_admin).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      # The job calls community.admins.each - verify this happens
      expect(community.admins).to include(admin1, admin2)
      
      MembershipCancelledJob.perform_now(person.id, community.id)
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(MembershipCancelledJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(MembershipCancelledJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end
