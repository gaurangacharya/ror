# Guest Type Pricing Step Definitions

# Helper method for taking screenshots with descriptive names
def take_screenshot_guest_pricing(description)
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  filename = "tmp/screenshots/guest_pricing/guest_pricing_#{description}_#{timestamp}.png"
  FileUtils.mkdir_p('tmp/screenshots/guest_pricing')
  save_screenshot(filename)
  puts "📸 Screenshot saved: #{filename}"
end

# Profile Management Steps

Given(/^"([^"]*)" has guest type pricing enabled$/) do |username|
  person = Person.find_by(username: username)
  person.update!(guest_type_pricing_enabled: true)
end

Given(/^"([^"]*)" has guest type pricing disabled$/) do |username|
  person = Person.find_by(username: username)
  person.update!(guest_type_pricing_enabled: false)
end

Given(/^"([^"]*)" has guest type pricing disabled in profile$/) do |username|
  person = Person.find_by(username: username)
  person.update!(guest_type_pricing_enabled: false)
end

Given(/^"([^"]*)" has Ladera white label design enabled$/) do |username|
  person = Person.find_by(username: username)
  white_label = person.person_white_label || person.build_person_white_label
  white_label.design = 'ladera'
  white_label.save!
end

Given(/^"([^"]*)" has no Ladera white label design$/) do |username|
  person = Person.find_by(username: username)
  white_label = person.person_white_label
  if white_label
    white_label.update!(design: nil)
  end
end

When(/^I navigate to my profile settings page$/) do
  visit person_settings_path(@current_user)
end

When(/^I enable "Guest Type Pricing" in my profile$/) do
  check 'person_guest_type_pricing_enabled'
end

When(/^I save my profile settings$/) do
  click_button 'Save information'
end

Then(/^I should see a success message$/) do
  # In Rails, successful form submissions typically redirect and show success
  expect(page).to have_no_css('.error') # No error messages
  expect(current_path).to eq(person_settings_path(@current_user))
end

# Listing Creation Steps

When(/^I navigate to create a new listing$/) do
  visit new_listing_path
end

Then(/^I should see a "Visitor Price" field$/) do
  expect(page).to have_field('listing_visitor_price')
end

Then(/^I should see help text about visitor pricing$/) do
  expect(page).to have_text('This price will be shown to visitors')
end

When(/^I fill in the listing form with standard price "([^"]*)" and visitor price "([^"]*)"$/) do |standard_price, visitor_price|
  fill_in 'listing_title', with: 'Test Guest Pricing Listing'
  fill_in 'listing_price', with: standard_price
  fill_in 'listing_visitor_price', with: visitor_price
  fill_in 'listing_description', with: 'Test description for guest pricing'
  # Select category if required
  if page.has_select?('listing_category_id')
    select 'Services', from: 'listing_category_id'
  end
end

When(/^I save the listing$/) do
  click_button 'Post listing'
end

When(/^I create a listing with title "([^"]*)" and price ([^"]*)$/) do |title, price|
  visit new_listing_path
  fill_in 'listing_title', with: title
  fill_in 'listing_price', with: price.to_f
  fill_in 'listing_description', with: 'Test description'
  if page.has_select?('listing_category_id')
    select 'Services', from: 'listing_category_id'
  end
  click_button 'Post listing'
  @listing = Listing.find_by(title: title)
end

Then(/^the listing should have a standard price of "([^"]*)"$/) do |expected_price|
  listing = Listing.last
  expect(listing.price.format).to eq(expected_price)
end

Then(/^the listing should have a visitor price of "([^"]*)"$/) do |expected_price|
  listing = Listing.last
  expect(listing.visitor_price.format).to eq(expected_price)
end

Given(/^the listing "([^"]*)" has no visitor price set$/) do |listing_title|
  listing = Listing.find_by(title: listing_title)
  listing.update!(visitor_price_cents: nil, visitor_price_currency: nil)
end

Given(/^the listing "([^"]*)" has a standard price of "([^"]*)"$/) do |listing_title, price|
  listing = Listing.find_by(title: listing_title)
  # Extract numeric value from price string like "$0.00"
  price_value = price.gsub(/[$,]/, '').to_f
  listing.update!(price: Money.new(price_value * 100, 'USD'))
end

Given(/^there is another listing "([^"]*)" from "([^"]*)" with standard price "([^"]*)" and visitor price "([^"]*)"$/) do |title, username, standard_price, visitor_price|
  person = Person.find_by(username: username)
  standard_cents = standard_price.to_f * 100
  visitor_cents = visitor_price.to_f * 100
  
  listing = FactoryBot.create(:listing,
    title: title,
    author: person,
    community: @current_community,
    price: Money.new(standard_cents, 'USD'),
    visitor_price: Money.new(visitor_cents, 'USD'),
    description: "Test listing description"
  )
end

# Navigation Steps

When(/^I navigate to the listing page for "([^"]*)"$/) do |listing_title|
  listing = Listing.find_by(title: listing_title) || @listing
  raise "Could not find listing with title '#{listing_title}'" unless listing
  visit listing_path(listing.id)
  @listing = listing
end

When(/^I visit the listing page for "([^"]*)"$/) do |listing_title|
  listing = Listing.find_by(title: listing_title) || @listing
  raise "Could not find listing with title '#{listing_title}'" unless listing
  visit listing_path(listing.id)
  @listing = listing
end

When(/^I visit the guest pricing listing "([^"]*)"$/) do |listing_title|
  listing = Listing.find_by(title: listing_title) || @listing
  raise "Could not find listing with title '#{listing_title}'" unless listing
  visit listing_path(listing.id)
  @listing = listing
end

When(/^I go to that listing page$/) do
  visit listing_path(@listing.id)
end

When(/^I edit the listing "([^"]*)"$/) do |listing_title|
  listing = Listing.find_by(title: listing_title)
  visit edit_listing_path(id: listing.id)
end

When(/^I navigate away and return to the listing$/) do
  visit root_path
  visit listing_path(@listing.id)
end

# Guest Type Modal Interaction Steps

# Modal step is defined in ladera_guest_type_steps.rb

# Modal step is defined in ladera_guest_type_steps.rb

When(/^I select "([^"]*)" in the guest type modal$/) do |guest_type|
  case guest_type.downcase
  when 'hotel guest'
    click_button 'Hotel Guest'
  when 'visitor'
    click_button 'Visitor'
  end
end

When(/^I try to close the modal without selecting$/) do
  # Try clicking the X button or overlay
  if page.has_css?('.lightbox-x')
    find('.lightbox-x').click
  end
end

Then(/^the modal should remain visible$/) do
  expect(page).to have_css('#ladera-guest-type-modal', visible: true)
end

Then(/^the modal should close$/) do
  expect(page).to have_no_css('#ladera-guest-type-modal', visible: true)
end

# Price Display Steps

Then(/^I should see "([^"]*)" as the displayed price$/) do |expected_price|
  expect(page).to have_text(expected_price)
end

Then(/^I should see "([^"]*)" as the hotel guest price$/) do |expected_price|
  expect(page).to have_text(expected_price)
end

Then(/^I should see "([^"]*)" as the visitor price$/) do |expected_price|
  expect(page).to have_text(expected_price)
end

Then(/^I should see "Complimentary" instead of price$/) do
  expect(page).to have_text('Complimentary')
  expect(page).to have_no_text('$0')
end

Then(/^I should not see the guest type selection modal again$/) do
  expect(page).to have_no_css('#ladera-guest-type-modal', visible: true)
end

# Booking and Transaction Steps

When(/^I proceed to book the experience$/) do
  # Find and click the booking button
  if page.has_button?('Request this')
    click_button 'Request this'
  elsif page.has_button?('Book now')
    click_button 'Book now'
  elsif page.has_link?('Request this')
    click_link 'Request this'
  end
end

Then(/^the transaction should use the standard price of "([^"]*)"$/) do |expected_price|
  # Check if we're on the transaction page and verify the price
  expect(current_path).to match(/transactions/)
  price_cents = expected_price.gsub(/[$,]/, '').to_f * 100
  expect(page).to have_text(expected_price) # Price should be displayed on transaction page
end

Then(/^the transaction should use the visitor price of "([^"]*)"$/) do |expected_price|
  expect(current_path).to match(/transactions/)
  price_cents = expected_price.gsub(/[$,]/, '').to_f * 100
  expect(page).to have_text(expected_price)
end

Then(/^the transaction should be free$/) do
  expect(current_path).to match(/transactions/)
  expect(page).to have_text('Complimentary')
end

# Admin Steps

Given(/^"([^"]*)" is community admin$/) do |username|
  person = Person.find_by(username: username)
  membership = CommunityMembership.find_by(person: person, community: @current_community)
  membership.update!(admin: true) if membership
end

When(/^I navigate to admin member management$/) do
  visit admin_community_community_memberships_path(@current_community)
end

When(/^I edit the user "([^"]*)"$/) do |username|
  person = Person.find_by(username: username)
  membership = CommunityMembership.find_by(person: person, community: @current_community)
  visit edit_admin_community_community_membership_path(@current_community, membership)
end

When(/^I enable "Guest Type Pricing" for that user$/) do
  check 'community_membership_person_attributes_guest_type_pricing_enabled'
end

When(/^I save the user settings$/) do
  click_button 'Save'
end

Then(/^I should see admin notes about visitor pricing$/) do
  expect(page).to have_text('Admin Note')
end

Then(/^I should see a warning that the author needs guest type pricing enabled$/) do
  expect(page).to have_text('the listing author needs to enable')
end

Then(/^I should see instructions to enable it in the user's profile$/) do
  expect(page).to have_text('Guest Type Pricing')
end

When(/^I change the visitor price to "([^"]*)"$/) do |new_price|
  fill_in 'listing_visitor_price', with: new_price
end

Then(/^I should see "Guest Pricing" column$/) do
  expect(page).to have_text('Guest Pricing')
end

Then(/^I should see a checkmark next to "([^"]*)"$/) do |username|
  person = Person.find_by(username: username)
  # Find the table row for this user and check for checkmark icon
  within(:xpath, "//tr[contains(., '#{person.given_name} #{person.family_name}')]") do
    expect(page).to have_css('i.ss-check')
  end
end

Then(/^I should see an X next to "([^"]*)"$/) do |username|
  person = Person.find_by(username: username)
  within(:xpath, "//tr[contains(., '#{person.given_name} #{person.family_name}')]") do
    expect(page).to have_css('i.ss-ban')
  end
end

# Login and Authentication Steps

When(/^I am not currently logged in$/) do
  logout
end

When(/^I try to close the modal without selecting$/) do
  # Simulate trying to close modal by clicking backdrop
  page.execute_script("$('.lightbox').click();")
end

Then(/^I should be redirected to login$/) do
  expect(current_path).to match(/login|sign_in/)
end

# Debugging Steps

When(/^I take a screenshot for guest pricing "([^"]*)"$/) do |description|
  take_screenshot_guest_pricing(description)
end

When(/^I debug the current page$/) do
  puts "Current URL: #{current_url}"
  puts "Current path: #{current_path}"
  puts "Page title: #{page.title}"
  puts "Visible text sample: #{page.text[0..200]}..."
  take_screenshot_guest_pricing("debug_page")
end

# Additional missing step definitions

When(/^I select "([^"]*)"$/) do |selection|
  case selection.downcase
  when 'hotel guest'
    click_button 'Hotel Guest'
  when 'visitor'
    click_button 'Visitor'
  else
    click_button selection
  end
end

Then(/^when I select a guest type and try to book$/) do
  # Select a guest type first
  if page.has_css?('#ladera-guest-type-modal', visible: true)
    click_button 'Hotel Guest'
  end
  
  # Try to book
  if page.has_button?('Request this')
    click_button 'Request this'
  elsif page.has_button?('Book now')
    click_button 'Book now'
  elsif page.has_link?('Request this')
    click_link 'Request this'
  end
end

Then(/^I should see the pricing information$/) do
  # Check that pricing information is visible on the page
  expect(page).to have_text(/\$\d+/)
  expect(page).to have_no_css('#ladera-guest-type-modal', visible: true)
end