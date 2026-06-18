class Person::SetChargebee
  attr_reader :person

  def initialize(person:)
    @person = person
  end

  def run
    if person.chargebee_hosted_page_id.present? && person.chargebee_id.blank?
      ActiveRecord::Base.transaction do
        hosted_page = ChargeBee::HostedPage.retrieve(person.chargebee_hosted_page_id).hosted_page
        if hosted_page.state = "succeeded"
          person.subscribe_via_hosted_page(hosted_page)
          subscription = hosted_page.content.subscription
          membership_expires_at = subscription.trial_end || subscription.current_term_end
          person.update_columns(
            membership_status: Person::MEMBERSHIP_PREMIUM,
            membership_expires_at: Time.at(membership_expires_at)
          )
        end
      end
    end
  end
end
