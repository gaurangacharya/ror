class ChangeDefaultsToListingAvailability < ActiveRecord::Migration[5.1]
  def change
    change_column :listings, :availability, :string, limit: 32, default: 'booking'
    change_column :listings, :booking_mode, :string, default: 'hour'
  end
end
