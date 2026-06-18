module Fareharbor
  class Availability < Spyke::Base
    uri 'companies/:shortname/availabilities/:availability_id'

    has_many :custom_field_instances, uri: nil
    has_many :customer_type_rates, uri: nil
    has_one :item, uri: nil
  end
end
