class TestimonialGivenJob < ApplicationJob
  queue_as :mailers

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.second)
  end

  def perform(testimonial_id, community_id)
    community = Community.find(community_id)
    testimonial = Testimonial.find(testimonial_id)
    receiver = testimonial.receiver

    if receiver.should_receive?("email_about_new_received_testimonials")
      MailCarrier.deliver_now(PersonMailer.new_testimonial(testimonial, community))
    end
  end

end
