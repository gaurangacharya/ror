module Fareharbor
  class AvailabilityLodging < Spyke::Base
    uri 'companies/:shortname/availabilities/:availability_id/lodgings/'
  end
end
