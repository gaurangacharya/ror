@javascript
Feature: Ladera Guest Type Selection
  In order to provide appropriate pricing for different guest types
  As a user visiting a Ladera experience listing
  I want to select whether I am a visitor or hotel guest before making a reservation

  Background:
    Given there are following users:
      | person |
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Sunset Yoga Experience" from "kassi_testperson1" with category "Services"
    And the price of that listing is 150.00 USD per hour
    And the visitor price of that listing is 125.00 USD per hour
    And that listing has a description "Join us for a relaxing sunset yoga session with breathtaking views"
    And the community has a Ladera white label design

  Scenario: Guest type modal appears automatically when on Ladera experience
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    Then I should see "Sunset Yoga Experience"
    And I should not see "$125"
    And I should not see "$150"
    And I should not see "Select guest type"
    And I should not see "per hour"
    And I should see the guest type selection modal
    And I should see "Are you a Visitor or Hotel Guest?"
    And I should see "Visitor" button
    And I should see "Hotel Guest" button
    And I should see "I am visiting Ladera Resort"
    And I should see "I am staying at Ladera Resort"

  Scenario: Selecting Hotel Guest shows standard pricing and proceeds to booking
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page  
    And I should see the guest type selection modal
    When I click the "Hotel Guest" button
    Then the modal should close automatically
    And I should see "$150" 
    When I click the "Reserve Now" button
    Then I should proceed directly to booking

  Scenario: Selecting Visitor shows visitor pricing and proceeds to booking
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    When I click the "Visitor" button
    Then the modal should close automatically
    And I should see "$125"
    And I should see "Visitor Rate" indicator
    When I click the "Reserve Now" button
    Then I should proceed directly to booking

  Scenario: Price is hidden until guest type is selected
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    Then I should not see "$125"
    And I should not see "$150"
    And I should not see "per hour"

  Scenario: User can close modal and visitor pricing is shown
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    When I click the "Close" button
    Then the modal should close
    And I should see "$125"
    And I should see "Visitor Rate" indicator

  Scenario: User can dismiss modal by clicking backdrop and visitor pricing is shown
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    When I click on the modal backdrop
    Then the modal should close
    And I should see "$125"
    And I should see "Visitor Rate" indicator

  Scenario: Modal is accessible via keyboard navigation
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    Then the first guest type button should be focused
    When I press the Tab key
    Then the second guest type button should be focused
    When I press Enter
    Then the guest type should be selected

  Scenario: Feature only appears on Ladera experiences
    Given the community does not have a Ladera white label design
    And I am logged in as "kassi_testperson2"
    When I go to the listing page
    Then I should not see the guest type selection modal
    And I should proceed directly to booking

  Scenario: Error handling when JavaScript fails
    Given I am logged in as "kassi_testperson2"
    And JavaScript is disabled
    When I go to the listing page
    And I click the "Reserve Now" button
    Then I should proceed directly to booking
    And I should not see any JavaScript errors

  Scenario: Mobile responsive design
    Given I am logged in as "kassi_testperson2"
    And I am using a mobile device
    When I go to the listing page
    And I should see the guest type selection modal
    Then the modal should be properly sized for mobile
    And the buttons should be touch-friendly
    When I click the "Hotel Guest" button
    Then the selection should work correctly on mobile

  Scenario: Hotel guest transaction is created with standard pricing
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    When I click the "Hotel Guest" button
    Then the modal should close automatically
    When I click the "Reserve Now" button
    And I fill in booking details
    And I submit the booking form
    Then a transaction should be created with standard price "$150.00"
    And the transaction should have guest_type "hotel_guest"

  Scenario: Visitor transaction is created with visitor pricing
    Given I am logged in as "kassi_testperson2"
    When I go to the listing page
    And I should see the guest type selection modal
    When I click the "Visitor" button
    Then the modal should close
    When I click the "Reserve Now" button
    And I fill in booking details
    And I submit the booking form
    Then a transaction should be created with visitor price "$125.00"
    And the transaction should have guest_type "visitor"

  Scenario: Transaction without guest type uses standard pricing
    Given the community does not have a Ladera white label design
    And I am logged in as "kassi_testperson2"
    When I go to the listing page
    Then I should not see the guest type selection modal
    When I click the "Reserve Now" button
    And I fill in booking details
    And I submit the booking form
    Then a transaction should be created with standard price "$150.00"
    And the transaction should not have guest_type

  Scenario: Activity Types section is hidden for Ladera listings
    Given I am logged in as "kassi_testperson2"
    And the listing has Activity Types custom field with "Tours & Guides" selected
    When I go to the listing page
    Then I should not see "Activity Types:"
    And I should not see "Tours & Guides"
    And I should not see "Experiences"
    And I should not see "Classes & Lessons" 
    And I should not see "Equipment/Gear"
    And I should see the guest type selection modal

  Scenario: Activity Types section is visible for non-Ladera listings
    Given the community does not have a Ladera white label design
    And I am logged in as "kassi_testperson2"
    And the listing has Activity Types custom field with "Tours & Guides" selected
    When I go to the listing page
    Then I should see "Activity Types:"
    And I should see "Tours & Guides"
    And I should not see the guest type selection modal

  Scenario: Hotel guests see Complimentary when standard price is zero
    Given I am logged in as "kassi_testperson2"
    And the price of that listing is 0.00 USD per hour
    When I go to the listing page
    And I should see the guest type selection modal
    When I click the "Hotel Guest" button
    Then the modal should close automatically
    And I should see "Complimentary" instead of the price