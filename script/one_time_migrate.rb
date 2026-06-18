class OwnoutdoorsOneTimeDataBatchMigration  
  def get_tr_key(title, community)
    res = TranslationService::API::Api.translations.create(
      community.id, 
      [
        {
          translations: [
            {
              locale: 'en', 
              translation: title
            }
          ]
        }
      ])
    res.data.map{|x| x[:translation_key] }.first
  end

  def create_listing_shape(community)
    process = TransactionProcess.where(community_id: community.id, process: 'preauthorize', author_is_seller: true).first
    listing_shape = ListingShape.create!(
      community_id: community.id,
      transaction_process_id: process.id,
      price_enabled: true,
      shipping_enabled: true,
      availability: 'none',
      name: 'create-listing',
      name_tr_key: get_tr_key('Create Listing', community),
      action_button_tr_key: get_tr_key('Rent/Book/Buy', community),
      sort_priority: 0,
      deleted: false
    )
  end

  def create_unit_types(listing_shape, community)
    # INSERT INTO `listing_units` (`unit_type`, `quantity_selector`, `kind`, `listing_shape_id`) VALUES ('night', 'night', 'time', 4)
    standard_unit_types = [
     ['hour', 'number', 'time'],
     ['day',  'day', 'time'],
     ['night', 'night', 'time'],
     ['week', 'number', 'time'],
     ['month', 'number', 'time'],
    ]
    standard_unit_types.each do |unit_type, quantity_selector, kind|
      ListingUnit.create(unit_type: unit_type, quantity_selector: quantity_selector, kind: kind, listing_shape: listing_shape)
    end

    # INSERT INTO `listing_units` (`unit_type`, `quantity_selector`, `kind`,     `name_tr_key`,                           `selector_tr_key`,                    `listing_shape_id`) 
    #                      VALUES ('custom',    'number',            'quantity', '3275f15b-a447-47a2-9fa4-a201343d0e7c', '05c166fd-88b9-4c49-8a46-d27348c48af4', 4)
    custom_units = [
      ['activity', 'number', 'quantity', 'Number of activities'],
      ['person', 'number', 'quantity', 'Number of people'],
      ['1/2 hour', 'number', 'time', 'Number of items'],
      ['4 hours', 'number', 'time', 'Number of items'],
      ['8 hours', 'number', 'time', 'Number of items'],
    ]
    custom_units.each do |name, quantity_selector, kind, selector_name|
      ListingUnit.create(
        unit_type: 'custom', 
        quantity_selector: quantity_selector, 
        kind: kind, 
        listing_shape: listing_shape,
        name_tr_key: get_tr_key(name, community),
        selector_tr_key: get_tr_key(selector_name, community)
      )
    end
  end

  def mark_call_for_price(community)
    translations = CommunityTranslation.all.each_with_object({}){|row, result| result[row.translation_key] = row.translation }
    shape = community.listing_shapes.detect{|shape| translations[shape.name_tr_key].to_s.downcase == 'call for price' }
    return unless shape
    Listing.where(listing_shape_id: shape.id).update_all(call_for_price: true) 
  end

  def move_listings(listing_shape, community)
    Listing.where(community_id: community.id)
      .update_all(listing_shape_id: listing_shape.id, shape_name_tr_key: listing_shape.name_tr_key, action_button_tr_key: listing_shape.action_button_tr_key)
  end

  def rename_item_to_activity(community)
    CommunityTranslation.where(translation: 'item').update_all(translation: 'activity')
  end

  def change_activity_type_to_dropdown(community)
    field = CustomField.where(community_id: community.id).all.detect{|c| c.name == 'Activity Type'}
    return unless field
    CustomField.where(id: field.id).update_all(type: 'DropdownField')
  end

  def perform(community_id)
    Community.transaction do 
      community = Community.find(community_id)
      
      puts "Step 1. Create listing shape"
      listing_shape = create_listing_shape(community)
      listing_shape.assign_to_categories!
      
      puts "Step 2. Create unit types"
      create_unit_types(listing_shape, community)
      
      puts "Step 3. Mark `call_for_price`"
      mark_call_for_price(community)

      puts "Step 4. Move listings to new shape"
      move_listings(listing_shape, community)

      puts "Step 5. Rename `item` to `activity`"
      rename_item_to_activity(community)

      puts "Step 6. Change 'Activity Type' custom Checkbox field to Dropdown"
      change_activity_type_to_dropdown(community)

      puts "ALL DONE! Run rake ts:rebuild, restart server, check that everyting works"
    end
  end
end

OwnoutdoorsOneTimeDataBatchMigration.new.perform(ARGV[0])
