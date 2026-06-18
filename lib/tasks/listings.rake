require "csv"

class ListingDeleter
  FILE_NAME = 'non-3rd-party-deleted-listing-ids'.freeze
  FILE_EXTENSION = 'csv'.freeze

  def run
    file_name = "#{FILE_NAME}.#{FILE_EXTENSION}"
    file_path = File.join(Rails.root, 'tmp', file_name)
    if File.exist?(file_path)
      puts "File #{file_path} exist."
    else
      puts "Write: To delete listings count= #{to_delete_listing_ids.size}"
      File.write(file_path, to_delete_listing_ids.join("\r\n"))
    end
    from_file_listing_ids = []
    CSV.foreach(file_path, headers: false) do |row|
      from_file_listing_ids.push(row[0])
    end
    puts "File listings count= #{from_file_listing_ids.size}"
    Listing.where(id: from_file_listing_ids).in_batches.update_all(deleted: true)
  end

  private

  def to_delete_listing_ids
    @to_delete_listing_ids ||=
    Listing.where(ext_booking_url: nil).map(&:id) +
    Listing.where(ext_booking_url: '').map(&:id)
  end
end

namespace :listings do

  namespace :ext_booking do
    desc "Deletes exe booking"
    task :delete_non_ext => :environment do |t, args|
      # ActiveRecord::Base.logger = Logger.new(STDOUT)
      ListingDeleter.new.run
    end
  end

end
