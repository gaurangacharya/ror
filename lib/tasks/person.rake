namespace :person do
  desc 'Converts person\'s vendor according listings. Run single time'
  task set_vendor: :environment do
    Person.find_each do |person|
      person_listing_ids = person.listings.map(&:id)
      field_value_scope = DropdownFieldValue.where(custom_field_id: 13442, listing_id: person_listing_ids).joins(:selected_options)
      business_count = field_value_scope.where(custom_field_options: {id: 49220}).count
      individual_count = field_value_scope.where(custom_field_options: {id: 49221}).count
      puts "person=#{person.display_name} listings business=#{business_count} individual=#{individual_count}"
      if individual_count == 0 && business_count > 0
        person.update_column(:is_vendor, true)
      end
    end; nil
  end
end
