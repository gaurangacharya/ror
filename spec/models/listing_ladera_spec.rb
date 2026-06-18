require 'rails_helper'

RSpec.describe Listing, type: :model do
  describe "Ladera guest type pricing" do
    let(:community) { FactoryBot.create(:community) }
    let(:author) { FactoryBot.create(:person, community: community) }
    let(:listing) { FactoryBot.create(:listing, community: community, author: author, price: Money.new(15000, 'USD')) }

    before do
      # Create a Ladera white label design for the author
      @person_white_label = PersonWhiteLabel.create!(
        person: author,
        design: 'ladera'
      )
    end

    describe "#is_ladera_listing?" do
      it "returns true when author has Ladera design" do
        expect(listing.is_ladera_listing?).to be true
      end

      it "returns false when author doesn't have Ladera design" do
        @person_white_label.update!(design: nil)
        expect(listing.is_ladera_listing?).to be false
      end
    end

    describe "#has_visitor_pricing?" do
      it "returns true when visitor_price_cents is present and positive" do
        listing.update!(visitor_price_cents: 12500, visitor_price_currency: 'USD')
        expect(listing.has_visitor_pricing?).to be true
      end

      it "returns false when visitor_price_cents is nil" do
        listing.update!(visitor_price_cents: nil)
        expect(listing.has_visitor_pricing?).to be false
      end

      it "returns false when visitor_price_cents is zero" do
        listing.update!(visitor_price_cents: 0)
        expect(listing.has_visitor_pricing?).to be false
      end
    end

    describe "#price_for_guest_type" do
      before do
        listing.update!(visitor_price_cents: 12500, visitor_price_currency: 'USD')
      end

      it "returns standard price for hotel guests" do
        result = listing.price_for_guest_type('hotel_guest')
        expect(result).to eq(Money.new(15000, 'USD'))
      end

      it "returns visitor price for visitors when visitor price exists" do
        result = listing.price_for_guest_type('visitor')
        expect(result).to eq(Money.new(12500, 'USD'))
      end

      it "returns regular price for visitors when no visitor price" do
        listing.update!(visitor_price_cents: nil)
        result = listing.price_for_guest_type('visitor')
        expect(result).to eq(Money.new(15000, 'USD'))
      end

      it "returns regular price for unspecified guest type" do
        result = listing.price_for_guest_type(nil)
        expect(result).to eq(Money.new(15000, 'USD'))
      end
    end

    describe "#display_price_for_guest_type" do
      before do
        listing.update!(visitor_price_cents: 12500, visitor_price_currency: 'USD')
      end

      it "returns standard price for hotel guests when price > 0" do
        result = listing.display_price_for_guest_type('hotel_guest')
        expect(result).to eq(Money.new(15000, 'USD'))
      end

      it "returns 'Complimentary' for hotel guests when price is 0" do
        listing.update!(price_cents: 0)
        result = listing.display_price_for_guest_type('hotel_guest')
        expect(result).to eq('Complimentary')
      end

      it "returns visitor price for visitors" do
        result = listing.display_price_for_guest_type('visitor')
        expect(result).to eq(Money.new(12500, 'USD'))
      end
    end

    describe "visitor_price monetization" do
      it "properly monetizes visitor_price_cents with currency" do
        listing.update!(visitor_price_cents: 12500, visitor_price_currency: 'USD')
        expect(listing.visitor_price).to eq(Money.new(12500, 'USD'))
      end

      it "handles nil visitor_price_cents" do
        listing.update!(visitor_price_cents: nil)
        expect(listing.visitor_price).to be_nil
      end
    end
  end
end