require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe PageLoadedJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:community) { create(:community) }
  let(:person) { create(:person) }
  let(:membership) { create(:community_membership, community: community, person: person) }
  let(:host) { 'test.host' }

  it 'inherits from ApplicationJob' do
    expect(PageLoadedJob.superclass).to eq(ApplicationJob)
  end

  it 'enqueues job with correct arguments' do
    expect {
      PageLoadedJob.perform_later(membership.id, host)
    }.to have_enqueued_job(PageLoadedJob).with(membership.id, host)
  end

  describe '#perform' do
    context 'when last_page_load_date is not today' do
      before do
        membership.update(last_page_load_date: 1.day.ago)
      end

      it 'updates last_page_load_date to today' do
        travel_to Time.zone.today do
          PageLoadedJob.perform_now(membership.id, host)
          expect(membership.reload.last_page_load_date.to_date).to eq(Date.today)
        end
      end
    end

    context 'when last_page_load_date is today' do
      before do
        membership.update(last_page_load_date: Time.current)
      end

      it 'does not update last_page_load_date' do
        original_date = membership.last_page_load_date
        PageLoadedJob.perform_now(membership.id, host)
        expect(membership.reload.last_page_load_date).to eq(original_date)
      end
    end
  end
end 