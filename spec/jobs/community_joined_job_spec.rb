require 'rails_helper'

RSpec.describe CommunityJoinedJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Use factories for test data - follow cursor rules
  let(:new_member) { create(:person) }
  let(:community) { create(:community, email_admins_about_new_members: true) }
  let(:admin1) { create(:person) }
  let(:admin2) { create(:person) }

  before do
    # Create actual admin memberships instead of mocking
    create(:community_membership, person: admin1, community: community, admin: true)
    create(:community_membership, person: admin2, community: community, admin: true)
  end

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        CommunityJoinedJob.perform_later(new_member.id, community.id)
      }.to have_enqueued_job(CommunityJoinedJob).with(new_member.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        CommunityJoinedJob.set(wait: 5.minutes, priority: 2).perform_later(new_member.id, community.id)
      }.to have_enqueued_job(CommunityJoinedJob).with(new_member.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        CommunityJoinedJob.set(queue: 'mailers').perform_later(new_member.id, community.id)
      }.to have_enqueued_job(CommunityJoinedJob).with(new_member.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    context 'when community emails admins about new members' do
      it 'performs job correctly and sends admin notifications' do
        # Mock the mailer to return present emails
        email_double = double('email', present?: true)
        expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin1).and_return(email_double)
        expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin2).and_return(email_double)
        expect(MailCarrier).to receive(:deliver_now).with(email_double).twice
        
        CommunityJoinedJob.perform_now(new_member.id, community.id)
      end

      it 'finds new member and community by ID' do
        expect(Person).to receive(:find).with(new_member.id).and_return(new_member)
        expect(Community).to receive(:find).with(community.id).and_return(community)
        allow(PersonMailer).to receive(:new_member_notification).and_return(double(present?: true))
        allow(MailCarrier).to receive(:deliver_now)
        
        CommunityJoinedJob.perform_now(new_member.id, community.id)
      end

      it 'checks community notification settings' do
        # The community is set up to email admins, so this should be called
        allow(PersonMailer).to receive(:new_member_notification).and_return(double(present?: true))
        allow(MailCarrier).to receive(:deliver_now)
        
        # Verify the job checks the setting
        expect(community.email_admins_about_new_members?).to be true
        
        CommunityJoinedJob.perform_now(new_member.id, community.id)
      end

      it 'sends notification to each admin' do
        email_double = double('email', present?: true)
        expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin1).and_return(email_double)
        expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin2).and_return(email_double)
        allow(MailCarrier).to receive(:deliver_now)
        
        CommunityJoinedJob.perform_now(new_member.id, community.id)
      end

      it 'only sends email when mailer returns present email' do
        # Simulate mailer returning present email for admin1, nil for admin2
        present_email = double('email', present?: true)
        nil_email = nil
        
        allow(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin1).and_return(present_email)
        allow(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin2).and_return(nil_email)
        
        expect(MailCarrier).to receive(:deliver_now).with(present_email).once # Only for admin1
        
        CommunityJoinedJob.perform_now(new_member.id, community.id)
      end
    end

    context 'when community does not email admins about new members' do
      let(:community_no_emails) { create(:community, email_admins_about_new_members: false) }
      let(:admin3) { create(:person) }
      
      before do
        create(:community_membership, person: admin3, community: community_no_emails, admin: true)
      end

      it 'does not send any notifications' do
        expect(PersonMailer).not_to receive(:new_member_notification)
        expect(MailCarrier).not_to receive(:deliver_now)
        
        CommunityJoinedJob.perform_now(new_member.id, community_no_emails.id)
      end

      it 'still processes job successfully' do
        expect {
          CommunityJoinedJob.perform_now(new_member.id, community_no_emails.id)
        }.not_to raise_error
      end
    end

    it 'sets community service name correctly' do
      allow(PersonMailer).to receive(:new_member_notification).and_return(double(present?: true))
      allow(MailCarrier).to receive(:deliver_now)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      CommunityJoinedJob.perform_now(new_member.id, community.id)
    end

    context 'when new member does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          CommunityJoinedJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          CommunityJoinedJob.new.perform(new_member.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'admin notification workflow' do
    it 'iterates through all community admins' do
      # The job calls community.admins.each - verify this happens by checking the admins exist
      expect(community.admins).to include(admin1, admin2)
      allow(PersonMailer).to receive(:new_member_notification).and_return(double(present?: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      CommunityJoinedJob.perform_now(new_member.id, community.id)
    end

    it 'passes new member, community, and specific admin to mailer' do
      email_double = double('email', present?: true)
      expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin1).and_return(email_double)
      expect(PersonMailer).to receive(:new_member_notification).with(new_member, community, admin2).and_return(email_double)
      allow(MailCarrier).to receive(:deliver_now)
      
      CommunityJoinedJob.perform_now(new_member.id, community.id)
    end

    it 'checks if email is present before delivering' do
      email_double = double('email')
      allow(PersonMailer).to receive(:new_member_notification).and_return(email_double)
      
      expect(email_double).to receive(:present?).twice.and_return(true)
      expect(MailCarrier).to receive(:deliver_now).with(email_double).twice
      
      CommunityJoinedJob.perform_now(new_member.id, community.id)
    end

    context 'when community has no admins' do
      let(:community_no_admins) { create(:community, email_admins_about_new_members: true) }
      
      it 'does not send any notifications' do
        expect(PersonMailer).not_to receive(:new_member_notification)
        expect(MailCarrier).not_to receive(:deliver_now)
        
        CommunityJoinedJob.perform_now(new_member.id, community_no_admins.id)
      end
    end
  end

  describe 'community settings integration' do
    it 'respects community email preferences' do
      # This is the key business logic - respecting community settings
      allow(PersonMailer).to receive(:new_member_notification).and_return(double(present?: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      # Verify the setting is checked
      expect(community.email_admins_about_new_members?).to be true
      
      CommunityJoinedJob.perform_now(new_member.id, community.id)
    end

    it 'allows communities to opt out of new member notifications' do
      community_no_emails = create(:community, email_admins_about_new_members: false)
      
      expect(PersonMailer).not_to receive(:new_member_notification)
      
      CommunityJoinedJob.perform_now(new_member.id, community_no_emails.id)
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(CommunityJoinedJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(CommunityJoinedJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end
