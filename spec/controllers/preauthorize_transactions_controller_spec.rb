require 'spec_helper'

describe PreauthorizeTransactionsController, type: :controller do



end

describe PreauthorizeTransactionsController::ItemTotal do

  let(:item_total) { PreauthorizeTransactionsController::ItemTotal }

  it "calculates the item total" do
    expect(item_total.new(unit_price: Money.new(2500, "USD"), quantity: 10).total)
      .to eq(Money.new(25_000, "USD"))

    expect(item_total.new(unit_price: Money.new(0, "EUR"), quantity: 10).total)
      .to eq(Money.new(0, "EUR"))

    expect(item_total.new(unit_price: Money.new(2500, "USD"), quantity: 0).total)
      .to eq(Money.new(0, "USD"))
  end

  describe "Ladera guest type pricing" do
    let(:community) { FactoryBot.create(:community) }
    let(:regular_author) { FactoryBot.create(:person, community: community) }
    let(:ladera_author) { FactoryBot.create(:person, community: community) }
    let(:regular_listing) { FactoryBot.create(:listing, community: community, author: regular_author, price: Money.new(15000, 'USD')) }
    let(:ladera_listing) { FactoryBot.create(:listing, community: community, author: ladera_author, price: Money.new(15000, 'USD'), visitor_price_cents: 12500, visitor_price_currency: 'USD') }
    let(:person) { FactoryBot.create(:person, community: community) }

    before do
      # Set up Ladera white label for the ladera_author only
      PersonWhiteLabel.create!(
        person: ladera_author,
        design: 'ladera'
      )
      
      # Ensure proper community membership
      CommunityMembership.create!(person: person, community: community, status: 'accepted')
      CommunityMembership.create!(person: ladera_author, community: community, status: 'accepted')
      CommunityMembership.create!(person: regular_author, community: community, status: 'accepted')
    end

    context "with regular listing" do
      it "uses standard pricing regardless of guest_type" do
        tx_params = { guest_type: 'hotel_guest' }
        item_total_instance = item_total.new(listing: regular_listing, person: person, tx_params: tx_params)
        
        expect(item_total_instance.unit_price).to eq(Money.new(15000, 'USD'))
      end
    end

    context "with Ladera listing" do
      it "uses complimentary pricing for hotel guests" do
        tx_params = { guest_type: 'hotel_guest' }
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        
        expect(item_total_instance.unit_price).to eq(Money.new(0, 'USD'))
      end

      it "uses visitor pricing for visitors" do
        tx_params = { guest_type: 'visitor' }
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        
        expect(item_total_instance.unit_price).to eq(Money.new(12500, 'USD'))
      end

      it "uses standard pricing when no guest_type specified" do
        tx_params = {}
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        
        expect(item_total_instance.unit_price).to eq(Money.new(15000, 'USD'))
      end

      it "uses standard pricing when guest_type is nil" do
        tx_params = { guest_type: nil }
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        
        expect(item_total_instance.unit_price).to eq(Money.new(15000, 'USD'))
      end

      it "calculates correct total for hotel guests" do
        tx_params = { guest_type: 'hotel_guest' }
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        allow(ladera_listing).to receive(:calculate_tx_quantity).and_return(2)
        
        expect(item_total_instance.total).to eq(Money.new(0, 'USD'))
      end

      it "calculates correct total for visitors" do
        tx_params = { guest_type: 'visitor' }
        item_total_instance = item_total.new(listing: ladera_listing, person: person, tx_params: tx_params)
        allow(ladera_listing).to receive(:calculate_tx_quantity).and_return(2)
        
        expect(item_total_instance.total).to eq(Money.new(25000, 'USD')) # 12500 * 2
      end
    end
  end
end

describe PreauthorizeTransactionsController::ShippingTotal do

  let(:shipping_total) { PreauthorizeTransactionsController::ShippingTotal }

  it "calculates the shipping total" do
    expect(shipping_total.new(initial: Money.new(5000, "EUR"), additional: 0, quantity: 1).total)
      .to eq(Money.new(5000, "EUR"))

    expect(shipping_total.new(initial: Money.new(5000, "EUR"), additional: 0, quantity: 10).total)
      .to eq(Money.new(5000, "EUR"))

    expect(shipping_total.new(initial: Money.new(5000, "USD"), additional: Money.new(1000, "USD"), quantity: 1).total)
      .to eq(Money.new(5000, "USD"))

    expect(shipping_total.new(initial: Money.new(5000, "USD"), additional: Money.new(1000, "USD"), quantity: 5).total)
      .to eq(Money.new(9000, "USD"))
  end
end

describe PreauthorizeTransactionsController::OrderTotal do

  let(:item_total) { PreauthorizeTransactionsController::ItemTotal }
  let(:shipping_total) { PreauthorizeTransactionsController::ShippingTotal }
  let(:order_total) { PreauthorizeTransactionsController::OrderTotal }

  it "calculates the order total (item total + shipping total)" do
    items = item_total.new(unit_price: Money.new(25_000, "EUR"), quantity: 5)
    shipping = shipping_total.new(initial: Money.new(2_000, "EUR"), additional: Money.new(500, "EUR"), quantity: 5)

    expect(order_total.new(item_total: items, shipping_total: shipping).total)
      .to eq(Money.new(129_000, "EUR"))
  end
end

describe PreauthorizeTransactionsController::Validator do

  let(:validator) { PreauthorizeTransactionsController::Validator }

  describe "#validate_delivery_method" do

    context "valid" do
      it "passes valid delivery method" do
        params = {
          tx_params: {
            delivery: :shipping
          },
          shipping_enabled: true,
          pickup_enabled: true
        }

        expect(validator.validate_delivery_method(
          tx_params: {
            delivery: :shipping
          },
          shipping_enabled: true,
          pickup_enabled: true
        ).success).to eq(true)
      end
    end

    context "invalid" do

      it "fails for invalid delivery method" do
        params = {
          tx_params: {
            delivery: :shipping
          },
          shipping_enabled: false,
          pickup_enabled: false
        }

        expect(validator.validate_delivery_method(
          tx_params: {
            delivery: :shipping
          },
          shipping_enabled: false,
          pickup_enabled: false
        ).data[:code]).to eq(:delivery_method_missing)
      end

      it "fails if delivery method is missing" do

        params = {
          tx_params: {
            delivery: nil
          },
          shipping_enabled: true,
          pickup_enabled: true
        }

        expect(validator.validate_delivery_method(
          tx_params: {
            delivery: nil
          },
          shipping_enabled: true,
          pickup_enabled: true
        ).data[:code]).to eq(:delivery_method_missing)
      end
    end
  end

  describe "#validate_booking" do
    context "valid" do
      it "passes for valid booking dates" do
        params = {
          tx_params: {
            start_on: 1.day.from_now.to_date,
            end_on: 2.days.from_now.to_date
          },
          quantity_selector: :day
        }

        expect(validator.validate_booking(params).success).to eq(true)
      end

      it "passes if booking is not in use" do
        params = {
          tx_params: {},
          quantity_selector: :number
        }

        expect(validator.validate_booking(params).success).to eq(true)
      end
    end

    context "invalid" do
      it "fails if start date is after end date" do
        params = {
          tx_params: {
            start_on: 1.day.from_now.to_date,
            end_on: 2.days.ago.to_date
          },
          quantity_selector: :day
        }

        expect(validator.validate_booking(params).data[:code]).to eq(:end_cant_be_before_start)
      end

      it "fails if start date equals end date for night selector" do
        params = {
          tx_params: {
            start_on: 1.day.from_now.to_date,
            end_on: 1.day.from_now.to_date
          },
          quantity_selector: :night
        }

        expect(validator.validate_booking(params).data[:code]).to eq(:at_least_one_day_or_night_required)
      end

      it "fails if start date or end date is missing for day selector" do
        params = {
          tx_params: {},
          quantity_selector: :day
        }

        expect(validator.validate_booking(params).data[:code]).to eq(:dates_missing)
      end

      it "fails if start date or end date is missing for night selector" do
        params = {
          tx_params: {},
          quantity_selector: :night
        }

        expect(validator.validate_booking(params).data[:code]).to eq(:dates_missing)
      end
    end
  end

  describe "#validate_transaction_agreement" do
    context "valid" do
      it "passes if agreement is in use and agreed" do
        params = {
          tx_params: {
            contract_agreed: true
          },
          transaction_agreement_in_use: true
        }

        expect(validator.validate_transaction_agreement(params).success).to eq(true)
      end

      it "passes if agreement is not in use" do
        params = {
          tx_params: {},
          transaction_agreement_in_use: false
        }

        expect(validator.validate_transaction_agreement(params).success).to eq(true)
      end

    end

    context "invalid" do
      it "fails if agreement is in use but not agreed" do
        params = {
          tx_params: {
            contract_agreed: false
          },
          transaction_agreement_in_use: true
        }

        expect(validator.validate_transaction_agreement(params).data[:code]).to eq(:agreement_missing)

      end
    end
  end
end
