require 'rails_helper'

RSpec.describe InvitationCreatedJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Use factories for test data - follow cursor rules
  let(:invitation) { create(:invitation) }
  let(:community) { create(:community) }

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        InvitationCreatedJob.perform_later(invitation.id, community.id)
      }.to have_enqueued_job(InvitationCreatedJob).with(invitation.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        InvitationCreatedJob.set(wait: 10.minutes, priority: 2).perform_later(invitation.id, community.id)
      }.to have_enqueued_job(InvitationCreatedJob).with(invitation.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        InvitationCreatedJob.set(queue: 'mailers').perform_later(invitation.id, community.id)
      }.to have_enqueued_job(InvitationCreatedJob).with(invitation.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    it 'performs job correctly' do
      expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation).and_return(double(deliver_now: true))
      expect(MailCarrier).to receive(:deliver_now)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    it 'finds invitation by ID' do
      expect(Invitation).to receive(:find).with(invitation.id).and_return(invitation)
      allow(PersonMailer).to receive(:invitation_to_kassi).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    it 'sets community service name correctly' do
      allow(PersonMailer).to receive(:invitation_to_kassi).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    context 'when invitation does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          InvitationCreatedJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'mailer integration' do
    it 'calls PersonMailer.invitation_to_kassi with invitation' do
      mailer_double = double('mailer')
      expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation).and_return(mailer_double)
      expect(MailCarrier).to receive(:deliver_now).with(mailer_double)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    it 'delivers email through MailCarrier' do
      mailer_double = double('mailer')
      allow(PersonMailer).to receive(:invitation_to_kassi).and_return(mailer_double)
      expect(MailCarrier).to receive(:deliver_now).with(mailer_double)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    it 'does not require community object for mailer call' do
      # Note: This job only uses community_id for service name setup, not for the mailer
      expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end
  end

  describe 'invitation workflow' do
    it 'sends invitation email immediately after creation' do
      # This job should be triggered when an invitation is created
      expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation)
      allow(MailCarrier).to receive(:deliver_now)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end

    it 'uses invitation object directly for email content' do
      # The invitation contains all necessary information (email, inviter, etc.)
      expect(PersonMailer).to receive(:invitation_to_kassi).with(invitation)
      allow(MailCarrier).to receive(:deliver_now)
      
      InvitationCreatedJob.perform_now(invitation.id, community.id)
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(InvitationCreatedJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(InvitationCreatedJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end
