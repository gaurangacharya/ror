@javascript
Feature: Guest Type Pricing System
  In order to provide appropriate pricing for different guest types
  As a user or admin managing listings with guest type pricing
  I want to control guest type pricing through user profiles and admin settings

  Background:
    Given there are following users:
      | person |
      | hotel_vendor |
      | regular_user |
    And there is a listing with title "Spa Treatment Experience" from "hotel_vendor" with category "Services"
    And the price of that listing is 200.00 USD per hour
    And the visitor price of that listing is 150.00 USD per hour

  Scenario: User with guest type pricing enabled shows modal
    Given "hotel_vendor" has guest type pricing enabled
    And I am logged in as "regular_user"
    When I go to the listing page
    Then I should see the guest type selection modal
    And I should see "Are you a Visitor or Hotel Guest?"

  Scenario: User without guest type pricing sees normal pricing
    Given "hotel_vendor" has guest type pricing disabled
    And I am logged in as "regular_user"
    When I go to the listing page
    Then I should not see the guest type selection modal

  Scenario: Hotel guest sees standard pricing
    Given "hotel_vendor" has guest type pricing enabled
    And I am logged in as "regular_user"
    When I go to the listing page
    And I select "Hotel Guest" in the guest type modal
    Then I should see "$200" as the displayed price

  Scenario: Visitor sees visitor pricing when available
    Given "hotel_vendor" has guest type pricing enabled
    And I am logged in as "regular_user"
    When I go to the listing page
    And I select "Visitor" in the guest type modal
    Then I should see "$150" as the displayed price

  Scenario: Legacy Ladera user maintains functionality
    Given "hotel_vendor" has Ladera white label design enabled
    And I am logged in as "regular_user"
    When I go to the listing page
    Then I should see the guest type selection modal

  Scenario: Listing owner does not see guest type modal
    Given "hotel_vendor" has guest type pricing enabled
    And I am logged in as "hotel_vendor"
    When I go to the listing page
    Then I should not see the guest type selection modal