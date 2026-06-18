require 'spec_helper'

describe TransactionMailer, type: :mailer do

  # Include EmailSpec stuff (https://github.com/bmabey/email-spec)
  include(EmailSpec::Helpers)
  include(EmailSpec::Matchers)


  describe "#booking_changed" do
    let(:listing) { FactoryBot.create(:listing, unit_type: 'hour') }
    let(:transaction) { FactoryBot.create(:transaction, listing: listing, unit_type: 'hour', unit_tr_key: listing.unit_tr_key) }
    let(:booking) { FactoryBot.create(:booking, tx: transaction, start_time: '2025-05-21 09:00', end_time: '2025-05-21 10:00', per_hour: true) }


    it "should send email about a booking change to the seller" do
      email = MailCarrier.deliver_now(TransactionMailer.booking_changed(transaction, true))
      assert !ActionMailer::Base.deliveries.empty?

      assert_equal transaction.author.confirmed_notification_email_addresses, email.to
      assert_equal "Booking changed for #{listing.title}", email.subject
    end

    it "should send email about a booking change to the buyer" do
      email = MailCarrier.deliver_now(TransactionMailer.booking_changed(transaction, false))
      assert !ActionMailer::Base.deliveries.empty?

      assert_equal transaction.starter.confirmed_notification_email_addresses, email.to
      assert_equal "Booking changed for #{listing.title}", email.subject
    end
  end
end 