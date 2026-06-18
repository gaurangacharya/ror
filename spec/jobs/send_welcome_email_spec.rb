require 'rails_helper'

RSpec.describe SendWelcomeEmail, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    
    # Disable retries for testing
    allow_any_instance_of(SendWelcomeEmail).to receive(:retry_on).and_return(nil)
    allow_any_instance_of(ApplicationJob).to receive(:retry_on).and_return(nil)
  end

  # Use factories for test data - follow cursor rules
  let(:person) { create(:person) }
  let(:community) { create(:community) }
  let!(:community_membership) { create(:community_membership, person: person, community: community) }

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        SendWelcomeEmail.perform_later(person.id, community.id)
      }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        SendWelcomeEmail.set(wait: 1.hour, priority: 5).perform_later(person.id, community.id)
      }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        SendWelcomeEmail.set(queue: 'mailers').perform_later(person.id, community.id)
      }.to have_enqueued_job(SendWelcomeEmail).with(person.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    it 'performs job correctly' do
      expect(PersonMailer).to receive(:welcome_email).with(person, community).and_return(double(deliver_now: true))
      expect(MailCarrier).to receive(:deliver_now)
      
      perform_enqueued_jobs do
        SendWelcomeEmail.perform_later(person.id, community.id)
      end
    end

    it 'finds person and community by ID' do
      expect(Person).to receive(:find).with(person.id).once.and_return(person)
      expect(Community).to receive(:find).with(community.id).once.and_return(community)
      allow(PersonMailer).to receive(:welcome_email).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      
      perform_enqueued_jobs do
        SendWelcomeEmail.perform_later(person.id, community.id)
      end
    end

    it 'handles error conditions gracefully' do
      expect(Person).to receive(:find).with(999).once.and_raise(ActiveRecord::RecordNotFound.new("Couldn't find Person with 'id'=999"))
      
      expect {
        SendWelcomeEmail.new.perform(999, community.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sets community service name correctly' do
      allow(PersonMailer).to receive(:welcome_email).and_return(double(deliver_now: true))
      allow(MailCarrier).to receive(:deliver_now)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      perform_enqueued_jobs do
        SendWelcomeEmail.perform_later(person.id, community.id)
      end
    end

    context 'when person does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect(Person).to receive(:find).with(999).once.and_raise(ActiveRecord::RecordNotFound.new("Couldn't find Person with 'id'=999"))
        
        expect {
          SendWelcomeEmail.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect(Person).to receive(:find).with(person.id).once.and_return(person)
        expect(Community).to receive(:find).with(999).once.and_raise(ActiveRecord::RecordNotFound.new("Couldn't find Community with 'id'=999"))
        
        expect {
          SendWelcomeEmail.new.perform(person.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'mailer integration' do
    it 'calls PersonMailer.welcome_email with correct arguments' do
      mailer_double = double('mailer')
      expect(PersonMailer).to receive(:welcome_email).with(person, community).and_return(mailer_double)
      expect(MailCarrier).to receive(:deliver_now).with(mailer_double)
      
      perform_enqueued_jobs do
        SendWelcomeEmail.perform_later(person.id, community.id)
      end
    end

    it 'delivers email through MailCarrier' do
      mailer_double = double('mailer')
      allow(PersonMailer).to receive(:welcome_email).and_return(mailer_double)
      expect(MailCarrier).to receive(:deliver_now).with(mailer_double)
      
      perform_enqueued_jobs do
        SendWelcomeEmail.perform_later(person.id, community.id)
      end
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(SendWelcomeEmail.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(SendWelcomeEmail.included_modules).to include(DelayedSentryNotification)
    end
  end
end
