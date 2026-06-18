# lib/tasks/import_production.rake

namespace :db do
  desc "Import production database and update domains for local development"
  task import_production: :environment do
    # Allow non-interactive mode via environment variable
    non_interactive = ENV['NON_INTERACTIVE'] == 'true'
    
    # Ensure we're in development environment
    ENV['RAILS_ENV'] = 'development'
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    
    puts "🚀 Starting production database import and domain updates..."
    puts "🔧 Environment: #{Rails.env}"
    puts "🔧 Database environment check disabled for safety"
    
    # Configuration
    DOKKU_HOST = ENV['DOKKU_HOST'] || 'root@ownoutdoors-new.ithouse.io'
    DOKKU_APP = ENV['DOKKU_APP'] || 'ownoutdoors-production'
    
    # Step 1: Backup current local database
    puts "\n📦 Creating backup of current local database..."
    backup_file = "db/backups/local_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
    FileUtils.mkdir_p('db/backups')
    
    local_config = ActiveRecord::Base.connection_db_config.configuration_hash
    puts "local_config: #{local_config}"
    backup_cmd = build_mysqldump_command(local_config, backup_file)
    
    unless system(backup_cmd)
      puts "❌ Failed to backup local database"
      exit 1
    end
    puts "✅ Local database backed up to #{backup_file}"
    
    # Step 2: Get production database dump from Dokku
    puts "\n📥 Downloading production database from Dokku..."
    production_dump_file = "db/production_dump_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
    
    # First, let's check available MySQL databases on Dokku
    puts "🔍 Checking available MySQL databases on Dokku..."
    list_cmd = "ssh #{DOKKU_HOST} 'dokku mysql:list'"
    puts "Running: #{list_cmd}"
    
    unless system(list_cmd)
      puts "❌ Failed to list MySQL databases on Dokku"
      exit 1
    end
    
    # Export production database using the correct Dokku format
    production_dump_cmd = "ssh #{DOKKU_HOST} 'dokku --raw mysql:export #{DOKKU_APP}-mysql' > #{production_dump_file}"
    puts "Running: #{production_dump_cmd}"
    
    unless system(production_dump_cmd)
      puts "❌ Failed to download production database"
      exit 1
    end
    puts "✅ Production database downloaded to #{production_dump_file}"
    
    # Step 3: Drop and recreate local database
    puts "\n🗑️  Dropping and recreating local database..."
    
    # Ensure we're in development environment and disable protection
    ENV['RAILS_ENV'] = 'development'
    ENV['DISABLE_DATABASE_ENVIRONMENT_CHECK'] = '1'
    
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    
    # Step 4: Import production data
    puts "\n📤 Importing production data..."
    import_cmd = build_mysql_command(local_config, production_dump_file)
    puts "Debug: Import command: #{import_cmd}"
    
    unless system(import_cmd)
      puts "❌ Failed to import production database"
      exit 1
    end
    puts "✅ Production database imported successfully"
    
    # Step 5: Reconnect to database and update domains
    puts "\n🔄 Reconnecting to database..."
    ActiveRecord::Base.establish_connection
    
    # Step 6: Update Community.last domain to lvh.me
    puts "\n🌐 Updating Community.last domain to 'lvh.me'..."
    if Community.any?
      last_community = Community.last
      if last_community
        old_domain = last_community.domain
        last_community.update!(domain: 'lvh.me')
        puts "  📝 Community.last: #{old_domain} → lvh.me"
      else
        puts "  ⚠️  No communities found"
      end
    else
      puts "  ⚠️  No communities found in database"
    end
    
    # Step 7: Update PersonWhiteLabel domains to lvh.me
    puts "\n🏷️  Updating PersonWhiteLabel domain attributes to 'lvh.me'..."
    
    if defined?(PersonWhiteLabel)
      # Update all PersonWhiteLabel domains to lvh.me
      person_white_labels = PersonWhiteLabel.where.not(domain: ['', nil])
      
      if person_white_labels.any?
        puts "  Found #{person_white_labels.count} PersonWhiteLabel records with domains to update"
        
        person_white_labels.find_each do |pw|
          old_domain = pw.domain
          # Handle different domain formats
          if old_domain.start_with?('http://') || old_domain.start_with?('https://')
            # Handle URLs like https://ownoutdoors.com/en/rf/R-andesstr
            new_domain = old_domain.gsub(/https?:\/\/([^.]+)\.ownoutdoors\.com/, 'https://\1.lvh.me')
          elsif old_domain.include?('.ownoutdoors.com')
            # Handle domains like subdomain.ownoutdoors.com
            subdomain = old_domain.gsub('.ownoutdoors.com', '')
            new_domain = "#{subdomain}.lvh.me"
          elsif old_domain.include?('.')
            # Handle other domains with dots
            subdomain = old_domain.split('.').first
            new_domain = "#{subdomain}.lvh.me"
          else
            # Handle simple subdomains
            new_domain = "#{old_domain}.lvh.me"
          end
          
          pw.update!(domain: new_domain)
          puts "  📝 Updated: #{old_domain} → #{new_domain}"
        end
        
        puts "✅ Updated #{person_white_labels.count} PersonWhiteLabel records"
      else
        puts "  ℹ️  No PersonWhiteLabel records with domains found"
      end
    else
      puts "⚠️  PersonWhiteLabel model not found - skipping updates"
    end
    
    # Step 8: Update other models with domain attributes
    puts "\n🌐 Updating other models with domain attributes..."
    
    # Find all models with domain attribute
    models_with_domain = []
    ActiveRecord::Base.descendants.each do |model|
      next unless model.table_exists?
      next unless model.column_names.include?('domain')
      next if model.name == 'PersonWhiteLabel' # Already handled
      next if model.name == 'Community' # Already handled
      
      models_with_domain << model
    end
    
    models_with_domain.each do |model|
      # Update domains that are not already lvh.me and not empty
      domains_to_update = model.where.not(domain: ['', nil, 'lvh.me'])
      
      if domains_to_update.any?
        puts "  Found #{domains_to_update.count} #{model.name} records with domains to update"
        
        domains_to_update.find_each do |record|
          old_domain = record.domain
          # Extract subdomain if it's a full domain, otherwise use as is
          if old_domain.include?('.')
            subdomain = old_domain.split('.').first
            new_domain = "#{subdomain}.lvh.me"
          else
            new_domain = "#{old_domain}.lvh.me"
          end
          
          record.update!(domain: new_domain)
          puts "  📝 #{model.name}: #{old_domain} → #{new_domain}"
        end
        
        puts "  ✅ Updated #{domains_to_update.count} #{model.name} records"
      else
        puts "  ℹ️  No #{model.name} records with domains to update"
      end
    end
    
    # Step 9: Update all Person passwords to "password" for local development
    puts "\n🔐 Updating all Person passwords to 'password' for local development..."
    
    if defined?(Person)
      # Check if Person model has encrypted_password column (Rails/Devise style)
      if Person.column_names.include?('encrypted_password')
        # For encrypted passwords, we need to generate a new encrypted password
        # This assumes the app uses Devise or similar authentication
        password = 'password'
        encrypted_password = BCrypt::Password.create(password)
        
        person_count = Person.count
        if person_count > 0
          puts "  Found #{person_count} Person records to update"
          
          # Update all persons with the new encrypted password
          Person.update_all(encrypted_password: encrypted_password)
          puts "  ✅ Updated #{person_count} Person records with encrypted password 'password'"
        else
          puts "  ℹ️  No Person records found"
        end
      elsif Person.column_names.include?('password')
        # For plain text passwords (less secure, but for local dev)
        person_count = Person.count
        if person_count > 0
          puts "  Found #{person_count} Person records to update"
          
          Person.update_all(password: 'password')
          puts "  ✅ Updated #{person_count} Person records with password 'password'"
        else
          puts "  ℹ️  No Person records found"
        end
      else
        puts "  ⚠️  Person model doesn't have password or encrypted_password column"
        puts "  Available columns: #{Person.column_names.join(', ')}"
      end
    else
      puts "⚠️  Person model not found - skipping password updates"
    end
    
    # Step 10: Run any additional data transformations
    puts "\n🔧 Running additional local development transformations..."
    
    # Add any other local development specific changes here
    # Examples:
    # - Update email addresses to use a local domain
    # - Disable external API integrations
    # - Update file paths or URLs
    
    # Step 10: Clean up dump files (optional)
    puts "\n🧹 Cleaning up temporary files..."
    File.delete(production_dump_file) if File.exist?(production_dump_file)
    puts "✅ Temporary files cleaned up"
    
    puts "\n🎉 Production database import and domain updates completed successfully!"
    puts "📁 Local backup saved at: #{backup_file}"
    puts "🌐 All domains updated for local development"
    puts "\n📋 Summary of changes:"
    puts "  - Community.last domain set to 'lvh.me'"
    puts "  - All PersonWhiteLabel domains updated to use 'lvh.me' TLD"
    puts "  - Other model domains updated to use 'lvh.me' TLD"
    puts "  - All Person passwords set to 'password' for local development"
  end
  
  private
  
  def build_mysqldump_command(config, output_file)
    cmd_parts = ["mysqldump"]
    cmd_parts << "-h #{config[:host]}" if config[:host]
    cmd_parts << "-P #{config[:port] || 3306}"
    cmd_parts << "-u #{config[:username]}" if config[:username]
    cmd_parts << "-p#{config[:password]}" if config[:password]
    cmd_parts << "--single-transaction --routines --triggers"
    cmd_parts << "--add-drop-database --databases"
    cmd_parts << config[:database] if config[:database]
    cmd_parts << "> #{output_file}"
    
    cmd_parts.join(' ')
  end
  
  def build_mysql_command(config, input_file)
    cmd_parts = ["mysql"]
    cmd_parts << "-h #{config[:host]}" if config[:host]
    cmd_parts << "-P #{config[:port] || 3306}"
    cmd_parts << "-u #{config[:username]}" if config[:username]
    cmd_parts << "-p#{config[:password]}" if config[:password]
    cmd_parts << config[:database] if config[:database]
    cmd_parts << "< #{input_file}"
    
    cmd_parts.join(' ')
  end
end
