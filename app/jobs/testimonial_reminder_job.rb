#reminder is sent to both parties, no need for recipient id anymore
class TestimonialReminderJob < ApplicationJob

  queue_as :transactions

  include DelayedSentryNotification

  before_perform do |job|
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(arguments.third)
  end

  def perform(conversation_id, recipient_id, community_id)
    return if Maybe(::PlanService::API::Api.plans.get_current(community_id: community_id).data)[:expired].or_else(false)

    transaction = Transaction.find(conversation_id)
    community = Community.find(community_id)

    if should_send_author_reminder?(transaction)
      MailCarrier.deliver_now(PersonMailer.send("testimonial_reminder", transaction, transaction.author, community))
    end

    if should_send_starter_reminder?(transaction)
      MailCarrier.deliver_now(PersonMailer.send("testimonial_reminder", transaction, transaction.starter, community))
    end
  end

  def should_send_author_reminder?(transaction)
    transaction.testimonial_from_author.nil? &&
      !transaction.author_skipped_feedback &&
      transaction.author.should_receive?("email_about_testimonial_reminders")
  end

  def should_send_starter_reminder?(transaction)
    transaction.testimonial_from_starter.nil? &&
      !transaction.starter_skipped_feedback &&
      transaction.starter.should_receive?("email_about_testimonial_reminders")
  end

end
