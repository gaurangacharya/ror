namespace :assets do
  desc "Analyze current asset storage usage and estimate migration size"
  task analyze_migration: :environment do
    puts "=== Asset Migration Analysis ==="
    
    total_size = 0
    total_files = 0
    
    # Models with attachments to analyze
    models_to_analyze = [
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
    
    puts "\n📊 Asset Analysis by Model:"
    puts "=" * 60
    
    models_to_analyze.each do |config|
      model_class = config[:model]
      attachment_name = config[:attachment]
      
      records = model_class.where.not("#{attachment_name}_file_name" => nil)
      record_count = records.count
      
      next if record_count == 0
      
      model_size = 0
      model_files = 0
      
      records.find_each do |record|
        attachment = record.send(attachment_name)
        next unless attachment.present? && attachment.exists?
        
        styles = attachment.styles.keys + [:original]
        
        styles.each do |style|
          local_path = attachment.path(style)
          if File.exist?(local_path)
            file_size = File.size(local_path)
            model_size += file_size
            model_files += 1
          end
        end
      end
      
      total_size += model_size
      total_files += model_files
      
      puts "📁 #{model_class.name}##{attachment_name}"
      puts "   Records: #{record_count}"
      puts "   Files: #{model_files}"
      puts "   Size: #{format_file_size(model_size)}"
      puts ""
    end
    
    puts "=" * 60
    puts "📈 Total Migration Summary:"
    puts "   Total Files: #{total_files}"
    puts "   Total Size: #{format_file_size(total_size)}"
    puts "   Estimated S3 Cost (monthly): $#{estimate_s3_cost(total_size)}"
    puts ""
    
    # Check public/system directory size
    system_path = Rails.root.join('public', 'system')
    if Dir.exist?(system_path)
      system_size = directory_size(system_path)
      puts "📂 Current public/system directory size: #{format_file_size(system_size)}"
      puts "💾 Disk space that will be freed: #{format_file_size(system_size)}"
    end
    
    puts "\n✅ Ready to migrate! Run 'rails assets:migrate_to_s3' to start."
  end
  
  desc "Dry run of S3 migration - shows what would be migrated without actually doing it"
  task dry_run_migration: :environment do
    puts "=== S3 Migration Dry Run ==="
    puts "This shows what would be migrated without actually uploading files.\n"
    
    # Check if S3 is configured
    unless APP_CONFIG.s3_bucket_name && APP_CONFIG.aws_access_key_id && APP_CONFIG.aws_secret_access_key
      puts "❌ ERROR: S3 configuration not found. Please configure S3 credentials."
      exit 1
    end
    
    puts "✅ S3 Configuration found:"
    puts "   Bucket: #{APP_CONFIG.s3_bucket_name}"
    puts "   Region: #{APP_CONFIG.s3_region || 'us-east-1'}"
    puts ""
    
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
    
    models_to_migrate.each do |config|
      model_class = config[:model]
      attachment_name = config[:attachment]
      
      records = model_class.where.not("#{attachment_name}_file_name" => nil)
      next if records.count == 0
      
      puts "📋 #{model_class.name}##{attachment_name} (#{records.count} records)"
      
      records.limit(5).each do |record|
        attachment = record.send(attachment_name)
        next unless attachment.present? && attachment.exists?
        
        styles = attachment.styles.keys + [:original]
        
        styles.each do |style|
          local_path = attachment.path(style)
          if File.exist?(local_path)
            s3_key = generate_s3_key(model_class, attachment_name, record.id, style, attachment.original_filename)
            file_size = File.size(local_path)
            puts "   → #{s3_key} (#{format_file_size(file_size)})"
            total_files += 1
          end
        end
      end
      
      if records.count > 5
        remaining = records.count - 5
        puts "   ... and #{remaining} more records"
      end
      
      puts ""
    end
    
    puts "🎯 Dry run complete! #{total_files} files would be migrated."
    puts "Run 'rails assets:migrate_to_s3' to perform the actual migration."
  end
  
  private
  
  def format_file_size(size)
    units = %w[B KB MB GB TB]
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024.0
      unit_index += 1
    end
    
    "%.2f #{units[unit_index]}" % size
  end
  
  def estimate_s3_cost(size_in_bytes)
    # S3 Standard pricing estimate (as of 2024)
    # First 50 TB: $0.023 per GB per month
    size_in_gb = size_in_bytes / (1024.0 ** 3)
    cost = size_in_gb * 0.023
    "%.2f" % cost
  end
  
  def directory_size(path)
    total_size = 0
    Dir.glob(File.join(path, '**', '*')).each do |file|
      total_size += File.size(file) if File.file?(file)
    end
    total_size
  end
  
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