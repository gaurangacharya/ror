require 'rails_helper'

RSpec.describe Listing, type: :model do
  let(:community) { FactoryBot.create(:community) }
  let(:author) { FactoryBot.create(:person, community: community) }
  let(:listing) { FactoryBot.create(:listing, community: community, author: author, price: Money.new(15000, 'USD')) }

  describe "Guest type pricing functionality" do
    describe "#has_guest_type_pricing?" do
      context "when user has guest type pricing enabled in profile" do
        before { author.update!(guest_type_pricing_enabled: true) }

        it "returns true" do
          expect(listing.has_guest_type_pricing?).to be true
        end
      end

      context "when user has Ladera white label design (legacy)" do
        before do
          author.update!(guest_type_pricing_enabled: false)
          PersonWhiteLabel.create!(person: author, design: 'ladera')
        end

        it "returns true" do
          expect(listing.has_guest_type_pricing?).to be true
        end
      end

      context "when user has both profile setting and Ladera design" do
        before do
          author.update!(guest_type_pricing_enabled: true)
          PersonWhiteLabel.create!(person: author, design: 'ladera')
        end

        it "returns true" do
          expect(listing.has_guest_type_pricing?).to be true
        end
      end

      context "when user has neither profile setting nor Ladera design" do
        before do
          author.update!(guest_type_pricing_enabled: false)
          # Ensure no white label or design is nil
          if author.person_white_label
            author.person_white_label.update!(design: nil)
          end
        end

        it "returns false" do
          expect(listing.has_guest_type_pricing?).to be false
        end
      end

      context "when author is nil" do
        let(:listing) { FactoryBot.build(:listing, author: nil) }

        it "returns false" do
          expect(listing.has_guest_type_pricing?).to be false
        end
      end
    end

    describe "#is_ladera_listing? (legacy method)" do
      context "when user has guest type pricing enabled" do
        before { author.update!(guest_type_pricing_enabled: true) }

        it "returns true for backwards compatibility" do
          expect(listing.is_ladera_listing?).to be true
        end
      end

      context "when user has Ladera design" do
        before do
          author.update!(guest_type_pricing_enabled: false)
          PersonWhiteLabel.create!(person: author, design: 'ladera')
        end

        it "returns true for backwards compatibility" do
          expect(listing.is_ladera_listing?).to be true
        end
      end
    end

    describe "#price_for_guest_type" do
      before do
        author.update!(guest_type_pricing_enabled: true)
        listing.update!(visitor_price: Money.new(12500, 'USD')) # $125
      end

      context "when guest type is hotel_guest" do
        it "returns the standard price" do
          expect(listing.price_for_guest_type('hotel_guest')).to eq(listing.price)
        end
      end

      context "when guest type is visitor" do
        context "and visitor price is set" do
          it "returns the visitor price" do
            expect(listing.price_for_guest_type('visitor')).to eq(listing.visitor_price)
          end
        end

        context "and visitor price is not set" do
          before { listing.update!(visitor_price: nil) }

          it "returns the standard price" do
            expect(listing.price_for_guest_type('visitor')).to eq(listing.price)
          end
        end
      end

      context "when guest type is unrecognized" do
        it "returns the standard price" do
          expect(listing.price_for_guest_type('unknown')).to eq(listing.price)
        end
      end

      context "when guest type is nil" do
        it "returns the standard price" do
          expect(listing.price_for_guest_type(nil)).to eq(listing.price)
        end
      end
    end

    describe "#display_price_for_guest_type" do
      before do
        author.update!(guest_type_pricing_enabled: true)
        listing.update!(visitor_price: Money.new(12500, 'USD'))
      end

      context "when hotel guest with paid service" do
        it "returns the formatted price" do
          expect(listing.display_price_for_guest_type('hotel_guest')).to eq(listing.price)
        end
      end

      context "when hotel guest with free service" do
        before { listing.update!(price: Money.new(0, 'USD')) }

        it "returns 'Complimentary'" do
          expect(listing.display_price_for_guest_type('hotel_guest')).to eq('Complimentary')
        end
      end

      context "when visitor with visitor pricing set" do
        it "returns the visitor price" do
          expect(listing.display_price_for_guest_type('visitor')).to eq(listing.visitor_price)
        end
      end

      context "when visitor without visitor pricing" do
        before { listing.update!(visitor_price: nil) }

        it "returns the standard price" do
          expect(listing.display_price_for_guest_type('visitor')).to eq(listing.price)
        end
      end
    end

    describe "#has_visitor_pricing?" do
      context "when visitor price is set and greater than 0" do
        before { listing.update!(visitor_price: Money.new(10000, 'USD')) }

        it "returns true" do
          expect(listing.has_visitor_pricing?).to be true
        end
      end

      context "when visitor price is 0" do
        before { listing.update!(visitor_price: Money.new(0, 'USD')) }

        it "returns false" do
          expect(listing.has_visitor_pricing?).to be false
        end
      end

      context "when visitor price is nil" do
        before { listing.update!(visitor_price: nil) }

        it "returns false" do
          expect(listing.has_visitor_pricing?).to be false
        end
      end
    end
  end

  describe "Integration with existing premium pricing" do
    let(:premium_user) { FactoryBot.create(:person, community: community, membership_status: 'premium') }
    let(:premium_listing) { FactoryBot.create(:listing, community: community, author: premium_user, price: Money.new(10000, 'USD')) }

    before do
      premium_user.update!(guest_type_pricing_enabled: true)
      premium_listing.update!(visitor_price: Money.new(8000, 'USD'))
    end

    it "guest type pricing works independently of premium status" do
      expect(premium_listing.has_guest_type_pricing?).to be true
      expect(premium_listing.price_for_guest_type('visitor')).to eq(Money.new(8000, 'USD'))
      expect(premium_listing.price_for_guest_type('hotel_guest')).to eq(Money.new(10000, 'USD'))
    end
  end
end