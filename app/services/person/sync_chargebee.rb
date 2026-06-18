# Go through all people's records.
# It retrieves subscription and update persona's status.
class Person::SyncChargebee
  class << self
    def run
      ::Person.chargebee.find_each do |person|
        next unless person.subscription

        result = ChargeBee::Subscription.retrieve(person.subscription.chargebee_id)
        chargebee_subscription = result.subscription
        membership_expires_at = chargebee_subscription.trial_end || chargebee_subscription.current_term_end
        puts "person='#{person.username}' membership_expires_at=#{membership_expires_at && Time.at(membership_expires_at)}"
        person.update_columns(
          membership_status: ::Person::MEMBERSHIP_PREMIUM,
          membership_expires_at: membership_expires_at && Time.at(membership_expires_at)
        )
      end
    end
  end
end
