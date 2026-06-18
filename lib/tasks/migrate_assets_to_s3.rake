namespace :assets do
  desc "Migrate existing assets from local storage to S3"
  task migrate_to_s3: :environment do
    puts "Starting migration of assets to S3..."
    
    # Check if S3 is configured
    unless APP_CONFIG.s3_bucket_name && APP_CONFIG.aws_access_key_id && APP_CONFIG.aws_secret_access_key
      puts "ERROR: S3 configuration not found. Please configure S3 credentials."
      exit 1
    end
    
    # Initialize S3 client
    s3_client = Aws::S3::Client.new(
      region: APP_CONFIG.s3_region || 'us-east-1',
      access_key_id: APP_CONFIG.aws_access_key_id,
      secret_access_key: APP_CONFIG.aws_secret_access_key
    )
    
    bucket_name = APP_CONFIG.s3_bucket_name
    
    # Models with attachments to migrate
    models_to_migrate = [
      { model: ListingImage, attachment: :image },
      { model: Person, attachment: :image },
      { model: Community, attachment: :logo },
      { model: Community, attachment: :cover_photo },
      { model: Community, attachment: :wide_logo },
      { model: Community, attachment: :small_cover_photo },
      { model: Community, attachment: :favicon },
      { model: PersonWhiteLabel, attachment: :logo },
      { model: PersonWhiteLabel, attachment: :wide_logo },
      { model: Document, attachment: :document },
      { model: Listing, attachment: :pdf },
      { model: Person, attachment: :pdf },
      { model: Mercury::Image, attachment: :image }
    ]
    
    total_files = 0
    migrated_files = 0
    failed_files = 0
    
    models_to_migrate.each do |config|
      model_class = config[:model]
      attachment_name = config[:attachment]
      
      puts "\n=== Migrating #{model_class.name}##{attachment_name} ==="
      
      # Find all records with attachments
      records = model_class.where.not("#{attachment_name}_file_name" => nil)
      puts "Found #{records.count} records with #{attachment_name} attachments"
      
      records.find_each do |record|
        begin
          attachment = record.send(attachment_name)
          next unless attachment.present? && attachment.exists?
          
          # Get all styles for this attachment
          styles = attachment.styles.keys + [:original]
          
          styles.each do |style|
            begin
              # Get local file path
              local_path = attachment.path(style)
              next unless File.exist?(local_path)
              
              # Generate S3 key
              s3_key = generate_s3_key(model_class, attachment_name, record.id, style, attachment.original_filename)
              
              # Upload to S3
              File.open(local_path, 'rb') do |file|
                s3_client.put_object(
                  bucket: bucket_name,
                  key: s3_key,
                  body: file,
                  content_type: attachment.content_type,
                  cache_control: "public, max-age=#{APP_CONFIG.s3_cache_max_age || 31536000}",
                  acl: 'public-read'
                )
              end
              
              total_files += 1
              migrated_files += 1
              print "."
              
            rescue => e
              puts "\nFailed to migrate #{local_path}: #{e.message}"
              failed_files += 1
            end
          end
          
        rescue => e
          puts "\nError processing #{model_class.name}##{record.id}: #{e.message}"
          failed_files += 1
        end
      end
    end
    
    puts "\n\n=== Migration Summary ==="
    puts "Total files processed: #{total_files}"
    puts "Successfully migrated: #{migrated_files}"
    puts "Failed migrations: #{failed_files}"
    puts "Migration completed!"
  end
  
  desc "Verify S3 migration - check if files exist on S3"
  task verify_s3_migration: :environment do
    puts "Verifying S3 migration..."
    
    s3_client = Aws::S3::Client.new(
      region: APP_CONFIG.s3_region || 'us-east-1',
      access_key_id: APP_CONFIG.aws_access_key_id,
      secret_access_key: APP_CONFIG.aws_secret_access_key
    )
    
    bucket_name = APP_CONFIG.s3_bucket_name
    
    # Check a sample of files
    ListingImage.where.not(image_file_name: nil).limit(10).each do |image|
      s3_key = generate_s3_key(ListingImage, :image, image.id, :original, image.image_file_name)
      
      begin
        s3_client.head_object(bucket: bucket_name, key: s3_key)
        puts "✓ Found: #{s3_key}"
      rescue Aws::S3::Errors::NotFound
        puts "✗ Missing: #{s3_key}"
      rescue => e
        puts "✗ Error checking #{s3_key}: #{e.message}"
      end
    end
  end
  
  desc "Clean up local files after successful S3 migration"
  task cleanup_local_files: :environment do
    puts "WARNING: This will permanently delete local asset files!"
    puts "Make sure you have verified the S3 migration first."
    puts "Type 'yes' to continue:"
    
    input = STDIN.gets.chomp
    unless input.downcase == 'yes'
      puts "Cancelled."
      exit 0
    end
    
    puts "Cleaning up local files..."
    
    # Remove the public/system directory structure
    system_path = Rails.root.join('public', 'system')
    if Dir.exist?(system_path)
      FileUtils.rm_rf(system_path)
      puts "Removed #{system_path}"
    end
    
    puts "Local file cleanup completed!"
  end
  
  private
  
  def generate_s3_key(model_class, attachment_name, record_id, style, filename)
    # Generate S3 key similar to Paperclip's S3 path structure
    case model_class.name
    when 'ListingImage'
      "images/listing_images/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'Person'
      "images/people/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'Community'
      "images/communities/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'PersonWhiteLabel'
      "images/person_white_labels/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'Document'
      "documents/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'Listing'
      "pdfs/listings/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    when 'Mercury::Image'
      "images/mercury/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    else
      "attachments/#{model_class.name.underscore}/#{attachment_name}/#{record_id}/#{style}/#{filename}"
    end
  end
end 