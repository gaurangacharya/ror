namespace :referral_locations do
  desc "Geocode referral locations that are missing coordinates"
  task geocode_missing: :environment do
    puts "Finding referral locations missing coordinates..."
    
    # Find all people with referral_address but no coordinates
    people_needing_geocoding = Person.joins(:referral_location)
                                      .where.not(referral_address: [nil, ''])
                                      .where(locations: { latitude: nil })
                                      .or(
                                        Person.joins(:referral_location)
                                              .where.not(referral_address: [nil, ''])
                                              .where(locations: { longitude: nil })
                                      )
    
    total = people_needing_geocoding.count
    puts "Found #{total} people with referral addresses missing coordinates"
    
    return if total.zero?
    
    success_count = 0
    failure_count = 0
    
    people_needing_geocoding.find_each.with_index do |person, index|
      print "\rProcessing #{index + 1}/#{total}: #{person.username}..."
      
      location = person.referral_location
      address = person.referral_address
      
      if location && address.present?
        result = location.search_and_fill_latlng(address)
        
        if result
          location.save
          success_count += 1
          print " ✓"
        else
          failure_count += 1
          print " ✗ (geocoding failed)"
        end
      end
      
      # Rate limiting - Google allows 50 requests per second
      sleep(0.05) if (index + 1) % 50 == 0
    end
    
    puts "\n\nGeocoding complete!"
    puts "Success: #{success_count}"
    puts "Failed: #{failure_count}"
  end
  
  desc "List people with referral addresses but no coordinates"
  task list_missing: :environment do
    people = Person.joins(:referral_location)
                   .where.not(referral_address: [nil, ''])
                   .where(locations: { latitude: nil })
                   .or(
                     Person.joins(:referral_location)
                           .where.not(referral_address: [nil, ''])
                           .where(locations: { longitude: nil })
                   )
    
    puts "People with referral addresses missing coordinates:"
    puts "Username | Referral Address | Created At"
    puts "-" * 80
    
    people.each do |person|
      puts "#{person.username.ljust(30)} | #{person.referral_address.ljust(30)} | #{person.created_at}"
    end
    
    puts "\nTotal: #{people.count}"
  end
end



