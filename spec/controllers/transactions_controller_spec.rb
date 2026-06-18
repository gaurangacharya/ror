require 'spec_helper'

describe TransactionsController, type: :controller do
  let(:community) { FactoryBot.create(:community) }
  let(:author) { FactoryBot.create(:person, community: community) }
  let(:user) { FactoryBot.create(:person, community: community) }
  
  before do
    @current_community = community
    @current_user = user
    controller.instance_variable_set(:@current_community, community)
    controller.instance_variable_set(:@current_user, user)
    
    # Mock the transaction service
    allow(controller).to receive(:transaction_service).and_return(double('TransactionService'))
  end

  describe "Ladera guest type pricing in transaction creation" do
    let(:regular_author) { FactoryBot.create(:person, community: community) }
    let(:ladera_author) { FactoryBot.create(:person, community: community) }
    let(:regular_listing) { FactoryBot.create(:listing, community: community, author: regular_author, price: Money.new(15000, 'USD')) }
    let(:ladera_listing) { FactoryBot.create(:listing, community: community, author: ladera_author, price: Money.new(15000, 'USD'), visitor_price_cents: 12500, visitor_price_currency: 'USD') }

    before do
      # Set up Ladera white label for the ladera_author only
      PersonWhiteLabel.create!(
        person: ladera_author,
        design: 'ladera'
      )
      
      # Ensure proper community membership
      CommunityMembership.create!(person: user, community: community, status: 'accepted')
      CommunityMembership.create!(person: ladera_author, community: community, status: 'accepted')
      CommunityMembership.create!(person: regular_author, community: community, status: 'accepted')
    end

    describe "unit price calculation logic" do
      it "uses standard price for regular listings regardless of guest_type" do
        form = { guest_type: 'hotel_guest' }
        
        # Simulate the controller logic
        unit_price = if regular_listing.is_ladera_listing? && form[:guest_type].present?
                       regular_listing.price_for_guest_type(form[:guest_type])
                     else
                       regular_listing.price
                     end
        
        expect(unit_price).to eq(Money.new(15000, 'USD'))
      end

      it "uses complimentary price for Ladera hotel guests" do
        form = { guest_type: 'hotel_guest' }
        
        # Simulate the controller logic
        unit_price = if ladera_listing.is_ladera_listing? && form[:guest_type].present?
                       ladera_listing.price_for_guest_type(form[:guest_type])
                     else
                       ladera_listing.price
                     end
        
        expect(unit_price).to eq(Money.new(0, 'USD'))
      end

      it "uses visitor price for Ladera visitors" do
        form = { guest_type: 'visitor' }
        
        # Simulate the controller logic
        unit_price = if ladera_listing.is_ladera_listing? && form[:guest_type].present?
                       ladera_listing.price_for_guest_type(form[:guest_type])
                     else
                       ladera_listing.price
                     end
        
        expect(unit_price).to eq(Money.new(12500, 'USD'))
      end

      it "uses standard price for Ladera listings when no guest_type" do
        form = {}
        
        # Simulate the controller logic
        unit_price = if ladera_listing.is_ladera_listing? && form[:guest_type].present?
                       ladera_listing.price_for_guest_type(form[:guest_type])
                     else
                       ladera_listing.price
                     end
        
        expect(unit_price).to eq(Money.new(15000, 'USD'))
      end

      it "uses standard price for Ladera listings when guest_type is nil" do
        form = { guest_type: nil }
        
        # Simulate the controller logic
        unit_price = if ladera_listing.is_ladera_listing? && form[:guest_type].present?
                       ladera_listing.price_for_guest_type(form[:guest_type])
                     else
                       ladera_listing.price
                     end
        
        expect(unit_price).to eq(Money.new(15000, 'USD'))
      end
    end

    describe "TransactionForm parameter processing" do
      it "accepts guest_type parameter" do
        form_params = {
          listing_id: ladera_listing.id,
          message: "Test message",
          quantity: 1,
          guest_type: "hotel_guest"
        }

        form = TransactionsController::TransactionForm.validate(form_params)
        
        expect(form.success).to be true
        expect(form.data[:guest_type]).to eq("hotel_guest")
      end

      it "accepts nil guest_type parameter" do
        form_params = {
          listing_id: ladera_listing.id,
          message: "Test message", 
          quantity: 1,
          guest_type: nil
        }

        form = TransactionsController::TransactionForm.validate(form_params)
        
        expect(form.success).to be true
        expect(form.data[:guest_type]).to be_nil
      end

      it "accepts missing guest_type parameter" do
        form_params = {
          listing_id: ladera_listing.id,
          message: "Test message",
          quantity: 1
        }

        form = TransactionsController::TransactionForm.validate(form_params)
        
        expect(form.success).to be true
        expect(form.data.key?(:guest_type)).to be true
        expect(form.data[:guest_type]).to be_nil
      end
    end
  end
end