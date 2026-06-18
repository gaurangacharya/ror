class CreateSignupPlans < ActiveRecord::Migration[5.1]
  def change
    create_table :signup_plans do |t|
      t.string :code
      t.string :title
      t.string :subtitle
      t.string :price_title
      t.text :plan_body

      t.timestamps
    end

    make_plan('head', 'Plans', 'Connecting people to the Outdoors, encouraging active and healthy lifestyles, and providing businesses a booking platform for marketing, transacting, and increasing revenue.')

    free_body = <<-EOT
<p class="plan-item">Online Bookings and Payments via Stripe</p>
<p class="plan-item">Unlimited Listings and Pictures</p>
<p class="plan-item">Contact Information Displayed</p>
<p class="plan-item">Insert YouTube Videos for Each Listing</p>
<p class="plan-item">Manage Inventory and Availability Calendar</p>
<p class="plan-item">Electronic Waivers and Agreements</p>
EOT
    make_plan('personal', 'Personal', 'Individuals, Sole Proprietors, Peer to Peer Rentals', 'FREE', free_body)

    business_body = <<-EOT
<p class="plan-item">Online Bookings and Payments via Stripe</p>
<p class="plan-item">Unlimited Listings and Pictures</p>
<p class="plan-item">Contact Information Displayed</p>
<p class="plan-item">Insert YouTube Videos for Each Listing</p>
<p class="plan-item">Manage Inventory and Availability Calendar</p>
<p class="plan-item">Electronic Waivers and Agreements</p>
<p class="plan-item">Preferred Marketing</p>
<p class="plan-item">Insurance Options</p>
<p class="plan-item">Access to our Reseller Network (Optional – 18%)</p>
EOT
    make_plan('business', 'Business', 'Startups and Small Businesses', 'FREE', business_body)


    reseller_body = <<-EOT
<p class="plan-item plan-item__strong">Add a Revenue Stream</p>
<p class="plan-item plan-item__dotted">Earn 10% per Booking</p>
<p class="plan-item plan-item__dotted">Access to 100+ (and growing) activities, tours, rentals, etc.</p>
<p class="plan-item plan-item__strong">Enhance your Guest’s Experience</p>
<p class="plan-item plan-item__dotted">Screened Activity and Tour Operators</p>
<p class="plan-item plan-item__dotted">Certificates of Excellence on TripAdvisor &amp; top rated on Google</p>
<p class="plan-item plan-item__dotted">Hundreds and even Thousands of 4+ Star Rated Reviews</p>
<p class="plan-item plan-item__strong">Incentivize your employees</p>
<p class="plan-item plan-item__dotted">Share commission with employees</p>
<p class="plan-item plan-item__dotted">Attract and retain front desk and concierge personnel</p>
EOT
    make_plan('reseller', 'Reseller', 'Hotels, Motels, Travel Agents, AirBnBs, Visitor Centers, and More!', 'FREE – Web Version<br/>$95 - Self-Service Tablet for Guests', reseller_body)
  end

  def make_plan(code, title, subtitle, price_title = nil, plan_body = nil)
    SignupPlan.create(code: code, title: title, subtitle: subtitle, price_title: price_title, plan_body: plan_body)
  end
end
