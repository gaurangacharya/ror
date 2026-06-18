require 'rails_helper'

RSpec.describe TestimonialGivenJob, type: :job do
  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Use factories for test data - follow cursor rules
  let(:receiver) { create(:person) }
  let(:community) { create(:community) }
  # Use build for testimonial due to Sphinx infrastructure issues
  let(:testimonial) { build(:testimonial, receiver: receiver) }

  describe 'job enqueueing' do
    it 'enqueues job with correct arguments' do
      expect {
        TestimonialGivenJob.perform_later(testimonial.id, community.id)
      }.to have_enqueued_job(TestimonialGivenJob).with(testimonial.id, community.id)
    end

    it 'supports scheduling options' do
      expect {
        TestimonialGivenJob.set(wait: 15.minutes, priority: 4).perform_later(testimonial.id, community.id)
      }.to have_enqueued_job(TestimonialGivenJob).with(testimonial.id, community.id)
    end

    it 'supports queue specification' do
      expect {
        TestimonialGivenJob.set(queue: 'mailers').perform_later(testimonial.id, community.id)
      }.to have_enqueued_job(TestimonialGivenJob).with(testimonial.id, community.id).on_queue('mailers')
    end
  end

  describe 'job execution' do
    context 'when receiver should receive notifications' do
      before do
        allow(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials").and_return(true)
      end

      it 'performs job correctly and sends email' do
        # Strategic mock for Testimonial.find since testimonial factory may have Sphinx issues
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(PersonMailer).to receive(:new_testimonial).with(testimonial, community).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end

      it 'finds testimonial and community by ID' do
        expect(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        expect(Community).to receive(:find).with(community.id).and_return(community)
        allow(PersonMailer).to receive(:new_testimonial).and_return(double(deliver_now: true))
        allow(MailCarrier).to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end

      it 'checks receiver notification preferences' do
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials").and_return(true)
        allow(PersonMailer).to receive(:new_testimonial).and_return(double(deliver_now: true))
        allow(MailCarrier).to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end

      it 'sends testimonial notification email' do
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(PersonMailer).to receive(:new_testimonial).with(testimonial, community).and_return(double(deliver_now: true))
        expect(MailCarrier).to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end
    end

    context 'when receiver should not receive notifications' do
      before do
        allow(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials").and_return(false)
      end

      it 'does not send email when receiver opts out' do
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        expect(PersonMailer).not_to receive(:new_testimonial)
        expect(MailCarrier).not_to receive(:deliver_now)
        
        TestimonialGivenJob.perform_now(testimonial.id, community.id)
      end

      it 'still processes job successfully without sending email' do
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        allow(Community).to receive(:find).with(community.id).and_return(community)
        
        expect {
          TestimonialGivenJob.perform_now(testimonial.id, community.id)
        }.not_to raise_error
      end
    end

    it 'sets community service name correctly' do
      allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      allow(receiver).to receive(:should_receive?).and_return(false)
      expect(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id).with(community.id).at_least(:once)
      
      TestimonialGivenJob.perform_now(testimonial.id, community.id)
    end

    context 'when testimonial does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          TestimonialGivenJob.new.perform(999, community.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when community does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
        
        expect {
          TestimonialGivenJob.new.perform(testimonial.id, 999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'testimonial notification workflow' do
    it 'extracts receiver from testimonial' do
      allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      expect(testimonial).to receive(:receiver).and_return(receiver)
      allow(receiver).to receive(:should_receive?).and_return(false)
      
      TestimonialGivenJob.perform_now(testimonial.id, community.id)
    end

    it 'respects user notification preferences' do
      allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      
      # This is the key business logic - respecting user preferences
      expect(receiver).to receive(:should_receive?).with("email_about_new_received_testimonials")
      
      TestimonialGivenJob.perform_now(testimonial.id, community.id)
    end

    it 'passes both testimonial and community to mailer for context' do
      allow(Testimonial).to receive(:find).with(testimonial.id).and_return(testimonial)
      allow(Community).to receive(:find).with(community.id).and_return(community)
      allow(receiver).to receive(:should_receive?).and_return(true)
      
      expect(PersonMailer).to receive(:new_testimonial).with(testimonial, community)
      allow(MailCarrier).to receive(:deliver_now)
      
      TestimonialGivenJob.perform_now(testimonial.id, community.id)
    end
  end

  describe 'inheritance from ApplicationJob' do
    it 'inherits from ApplicationJob' do
      expect(TestimonialGivenJob.superclass).to eq(ApplicationJob)
    end

    it 'includes DelayedSentryNotification' do
      expect(TestimonialGivenJob.included_modules).to include(DelayedSentryNotification)
    end
  end
end
