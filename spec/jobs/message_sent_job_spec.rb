require 'rails_helper'

RSpec.describe MessageSentJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Use factories for test data - follow cursor rules
  let(:message) { create(:message) }
  let(:community) { create(:community) }

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        MessageSentJob.perform_later(message.id, community.id)
      }.to have_enqueued_job(MessageSentJob).with(message.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        MessageSentJob.set(wait: 5.minutes, priority: 3).perform_later(message.id, community.id)
      }.to have_enqueued_job(MessageSentJob).with(message.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        MessageSentJob.set(queue: 'mailers').perform_later(message.id, community.id)
      }.to have_enqueued_job(MessageSentJob).with(message.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    it 'performs job correctly' do
      # Strategic mock for Message.find since message factory may have Sphinx issues
      allow(Message).to receive(:find).with(message.id).and_return(message)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      expect(message).to receive(:send_email_to_participants).with(community)
      
      MessageSentJob.perform_now(message.id, community.id)
    end

    it 'finds message and community by ID' do
      expect(Message).to receive(:find).with(message.id).and_return(message)
      expect(Community).to receive(:find).with(community.id).and_return(community)
      allow(message).to receive(:send_email_to_participants)
      
      MessageSentJob.perform_now(message.id, community.id)
    end

    it 'calls send_email_to_participants on message' do
      allow(Message).to receive(:find).with(message.id).and_return(message)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      expect(message).to receive(:send_email_to_participants).with(community)
      
      MessageSentJob.perform_now(message.id, community.id)
    end

    it 'sets community service name correctly' do
      allow(Message).to receive(:find).with(message.id).and_return(message)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      allow(message).to receive(:send_email_to_participants)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      MessageSentJob.perform_now(message.id, community.id)
    end

    context 'when message does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          MessageSentJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(Message).to receive(:find).with(message.id).and_return(message)
        
        expect {
          MessageSentJob.new.perform(message.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'message notification workflow' do
    it 'delegates email sending to message object' do
      allow(Message).to receive(:find).with(message.id).and_return(message)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      
      # The job should delegate to the message's own email logic
      expect(message).to receive(:send_email_to_participants).with(community)
      
      MessageSentJob.perform_now(message.id, community.id)
    end

    it 'passes community context to message for email customization' do
      allow(Message).to receive(:find).with(message.id).and_return(message)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      
      # Community should be passed to allow for community-specific email customization
      expect(message).to receive(:send_email_to_participants).with(community)
      
      MessageSentJob.perform_now(message.id, community.id)
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(MessageSentJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(MessageSentJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end
