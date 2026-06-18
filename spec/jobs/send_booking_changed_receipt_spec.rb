require 'spec_helper'

RSpec.describe SendBookingChangedReceipt, type: :job do
  describe '#perform' do
    let(:listing) { FactoryBot.create(:listing, unit_type: 'hour') }
    let(:transaction) { FactoryBot.create(:transaction, listing: listing, unit_type: 'hour', unit_tr_key: listing.unit_tr_key) }
    let(:booking) { FactoryBot.create(:booking, tx: transaction, start_time: '2025-05-21 09:00', end_time: '2025-05-21 10:00', per_hour: true) }
    
    before do
      allow(Transaction).to receive(:find).with(transaction.id).and_return(transaction)
      allow(ApplicationHelper).to receive(:store_community_service_name_to_thread_from_community_id)
      allow(TransactionMailer).to receive(:booking_changed).and_return(double(deliver_now: true))
    end
    
    context 'when buyer modifies the booking' do
      it 'sends booking changed emails to seller' do
        sender_id = transaction.starter.id
        
        expect(TransactionMailer).to receive(:booking_changed).with(transaction, true).once

        SendBookingChangedReceipt.new.perform(transaction.id, sender_id)
      end
    end
    
    context 'when seller modifies the booking' do
      it 'sends booking changed emails to both buyer' do
        sender_id = transaction.author.id
        
        expect(TransactionMailer).to receive(:booking_changed).with(transaction, false).once

        SendBookingChangedReceipt.new.perform(transaction.id, sender_id)
      end
    end

    it 'does not raise an error when called with correct arguments' do
      sender = transaction.starter || transaction.author
      expect { SendBookingChangedReceipt.new.perform(transaction.id, sender.id) }.to_not raise_error
    end
  end
end 