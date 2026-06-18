require 'spec_helper'

describe InboxPresenter::ExportCsv do
  let(:community) { build(:community) }
  let(:person) { build(:person, community_id: community.id) }
  let(:author) { build(:person, community_id: community.id) }
  let(:listing) { build(:listing, author: author, community_id: community.id) }
  
  let(:conversation) do
    conversation = build(:conversation, community: community)
    build(:participation, conversation: conversation, person: author, is_read: false, is_starter: false)
    build(:participation, conversation: conversation, person: person, is_read: true, is_starter: true)
    allow(conversation).to receive(:last_activity_at).and_return(Time.now)
    conversation
  end
  
  let(:transaction) do
    tx = build(:transaction, 
      starter: person, 
      listing: listing, 
      community_id: community.id,
      listing_author_id: author.id
    )

    allow(conversation).to receive(:tx).and_return(tx)
    
    tx
  end
  
  before do
    allow(conversation).to receive(:messages).and_return([])
    
    email = build(:email, person: person, address: "test@example.com", confirmed_at: Time.now)
    allow(person).to receive_message_chain(:emails, :confirmed, :first).and_return(email)
  end
  
  describe "#generate" do
    it "generates a CSV with headers and data rows" do
      csv_data = []
      
      yielder = double("Yielder")
      allow(yielder).to receive(:<<) { |data| csv_data << data }
      
      allow(Enumerator).to receive(:new).and_yield(yielder)
      
      exporter = described_class.new(conversations: [conversation], full_domain: "https://example.com")
      exporter.generate
      

      expect(csv_data[0]).to include('hotel guest or visitor')
      expect(csv_data[0]).to include('refund amount')
    end
  end
  
  describe "row data" do
    context "with hotel guest and stripe refund" do
      let(:person) { build(:person, community_id: community.id, hotel_guest: true, name_on_reservation: "John Smith") }
      let(:transaction) do
        tx = build(:transaction, 
          starter: person, 
          listing: listing, 
          community_id: community.id,
          listing_author_id: author.id,
          payment_gateway: 'stripe'
        )
        allow(conversation).to receive(:tx).and_return(tx)
        tx
      end
      let(:stripe_payment) do
        build(:stripe_payment, 
          transaction_id: transaction.id, 
          community_id: community.id,
          payer_id: person.id,
          receiver_id: author.id,
          status: 'refunded',
          is_refunded: true,
          refund_amount_cents: 2000,
          currency: 'USD'
        )
      end
      
      before do
        allow(transaction).to receive(:stripe_payment).and_return(stripe_payment)
      end
      
      it "includes hotel guest status and refund amount" do
        exporter = described_class.new(conversations: [conversation], full_domain: "https://example.com")
        row_data = exporter.row(conversation)
        
        guest_index = row_data.index("Hotel Guest")
        expect(guest_index).not_to be_nil
        
        refund_amount_index = row_data.size - 1
        expect(row_data[refund_amount_index]).to include("$")
      end
    end
    
    context "with visitor" do
      let(:person) { build(:person, community_id: community.id, hotel_guest: false) }
      
      it "shows visitor when not a hotel guest" do
        exporter = described_class.new(conversations: [conversation], full_domain: "https://example.com")
        row_data = exporter.row(conversation)
        
        guest_index = row_data.index("Visitor")
        expect(guest_index).not_to be_nil
      end
    end
    
    context "with paypal refund" do
      let(:transaction) do
        tx = build(:transaction, 
          starter: person, 
          listing: listing, 
          community_id: community.id,
          listing_author_id: author.id,
          payment_gateway: 'paypal'
        )
        allow(conversation).to receive(:tx).and_return(tx)
        tx
      end
      let(:paypal_payment) do
        build(:paypal_payment, 
          transaction_id: transaction.id, 
          community_id: community.id,
          payer_id: person.id,
          receiver_id: author.id,
          payment_status: 'refunded',
          refund_total_cents: 3000,
          currency: 'USD'
        )
      end
      
      before do
        allow(transaction).to receive(:paypal_payment).and_return(paypal_payment)
      end
      
      it "includes refund amount in CSV row" do
        exporter = described_class.new(conversations: [conversation], full_domain: "https://example.com")
        row_data = exporter.row(conversation)
        
        refund_amount_index = row_data.size - 1
        refund_value = row_data[refund_amount_index]
        expect(refund_value).not_to eq("N/A")
        expect(refund_value).to include("$")
      end
    end
    
    context "with no refund" do
      let(:transaction) do
        tx = build(:transaction, 
          starter: person, 
          listing: listing, 
          community_id: community.id,
          listing_author_id: author.id,
          payment_gateway: 'stripe'
        )
        allow(conversation).to receive(:tx).and_return(tx)
        tx
      end
      let(:stripe_payment) do
        build(:stripe_payment, 
          transaction_id: transaction.id, 
          community_id: community.id,
          refund_amount_cents: nil,
          currency: 'USD'
        )
      end
      
      before do
        allow(transaction).to receive(:stripe_payment).and_return(stripe_payment)
      end
      
      it "shows N/A for refund amount when no refund exists" do
        exporter = described_class.new(conversations: [conversation], full_domain: "https://example.com")
        row_data = exporter.row(conversation)
        
        refund_amount_index = row_data.size - 1
        expect(row_data[refund_amount_index]).to eq("N/A")
      end
    end
  end
  
  describe "#first_row_column_names" do
    it "includes the new columns in the headers" do
      yielder = double("Yielder")
      expect(yielder).to receive(:<<) do |headers|
        expect(headers).to include('hotel guest or visitor')
        expect(headers).to include('refund amount')
      end
      
      exporter = described_class.new(conversations: [], full_domain: "https://example.com")
      exporter.first_row_column_names(yielder)
    end
  end
end 