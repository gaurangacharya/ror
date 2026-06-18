module ChargebeeRails
  module WebhooksControllerDecorator
    # The existing person subscribes through ChargeBee
    # @chargebee_event is pointless.
    # There are no links between HostedPage and Event in ChargeBee.
    def subscription_created
      Person.chargebee_first_time.each do |person|
        Person::SetChargebee.new(person: person).run
      end
    end
  end
end

::ChargebeeRails::WebhooksController.prepend(ChargebeeRails::WebhooksControllerDecorator)

