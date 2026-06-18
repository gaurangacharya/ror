module Fareharbor
  class BaseUpdater
    def convert_location(location:, location_type: nil)
      if location
        logger.info "Converting location data (Type: #{location_type})" if respond_to?(:logger)
        
        address = location["address"]
        if address
          logger.info "Processing address components" if respond_to?(:logger)
          
          address_ary = [
            address["street"],
            address["city"],
            address["province"],
            address["postal_code"],
            address["country"]
          ]
          address_str = address_ary.filter{|item| item.present?}.join(', ')
          
          logger.info "Address string: #{address_str}" if respond_to?(:logger)
          logger.info "Coordinates: #{location["latitude"]}, #{location["longitude"]}" if respond_to?(:logger)

          result = {
            address: address_str,
            google_address: address_str,
            latitude: location["latitude"],
            longitude: location["longitude"],
          }

          result[:location_type] = location_type if location_type
          
          logger.info "✓ Location conversion completed" if respond_to?(:logger)
          result
        else
          logger.warn "✗ No address data found in location" if respond_to?(:logger)
          nil
        end
      else
        logger.warn "✗ No location data provided" if respond_to?(:logger)
        nil
      end
    end

    def location_present?(location)
      if location
        logger.info "Checking if location data is complete" if respond_to?(:logger)
        
        address = location["address"]
        if address
          address_ary = [
            address["street"],
            address["city"],
            address["province"],
            address["postal_code"],
            address["country"]
          ]
          
          complete = address_ary.all?{|item| item.present?}
          logger.info "Location completeness check: #{complete ? 'COMPLETE' : 'INCOMPLETE'}" if respond_to?(:logger)
          
          if !complete
            missing_fields = address_ary.each_with_index.filter_map { |item, index| 
              ['street', 'city', 'province', 'postal_code', 'country'][index] if item.blank?
            }
            logger.warn "Missing address fields: #{missing_fields.join(', ')}" if respond_to?(:logger)
          end
          
          return complete
        else
          logger.warn "✗ No address data found in location" if respond_to?(:logger)
          return false
        end
      else
        logger.warn "✗ No location data provided" if respond_to?(:logger)
        return false
      end
    end
  end
end
