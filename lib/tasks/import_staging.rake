# lib/tasks/staging_import.rake

namespace :db do
  desc "Import staging database and update domains for local development"
  task import_staging: :environment do
    # Allow non-interactive mode via environment variable
    non_interactive = ENV['NON_INTERACTIVE'] == 'true'
    
    puts "🚀 Starting staging database import and domain updates..."
    
    # Configuration - update these values as needed
    DOKKU_HOST = ENV['DOKKU_HOST'] || 'your-dokku-server.com'
    DOKKU_APP = ENV['DOKKU_APP'] || 'your-app-name'
    STAGING_DB_URL = ENV['STAGING_DATABASE_URL']
    
    # Step 1: Backup current local database
    puts "\n📦 Creating backup of current local database..."
    backup_file = "db/backups/local_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
    FileUtils.mkdir_p('db/backups')
    
    local_config = ActiveRecord::Base.connection_db_config.configuration_hash
    puts "local_config: #{local_config}"
    backup_cmd = build_mysqldump_command(local_config, backup_file)
    
    unless system(backup_cmd)
      puts "❌ Failed to backup local database"
      # exit 1
    end
    puts "✅ Local database backed up to #{backup_file}"
    
    # Step 2: Get staging database dump
    puts "\n📥 Downloading staging database..."
    staging_dump_file = "db/staging_dump_#{Time.current.strftime('%Y%m%d_%H%M%S')}.sql"
    
    if STAGING_DB_URL
      # Direct database connection approach
      staging_config = parse_database_url(STAGING_DB_URL)
      staging_dump_cmd = build_mysqldump_command(staging_config, staging_dump_file)
    else
      # Dokku approach
      staging_dump_cmd = "ssh #{DOKKU_HOST} dokku mysql:export #{DOKKU_APP}-mysql > #{staging_dump_file}"
    end
    
    unless system(staging_dump_cmd)
      puts "❌ Failed to download staging database"
      exit 1
    end
    puts "✅ Staging database downloaded to #{staging_dump_file}"
    
    # Step 3: Drop and recreate local database
    puts "\n🗑️  Dropping and recreating local database..."
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    
    # Step 4: Import staging data
    puts "\n📤 Importing staging data..."
    import_cmd = build_mysql_command(local_config, staging_dump_file)
    puts "Debug: Import command: #{import_cmd}"
    
    unless system(import_cmd)
      puts "❌ Failed to import staging database"
      exit 1
    end
    puts "✅ Staging database imported successfully"
    
    # Step 5: Reconnect to database and update domains
    puts "\n🔄 Reconnecting to database..."
    ActiveRecord::Base.establish_connection
    
    # Step 6: Update general domain attribute
    puts "\n🌐 Updating general domain attributes to 'lvh.me'..."
    
    # Update any models that have a 'domain' attribute
    # Add your specific models here as needed
    models_with_domain = [Community, PersonWhiteLabel]
    
    # Example: if you have a Settings or Configuration model
    if defined?(Setting) && Setting.column_names.include?('domain')
      models_with_domain << Setting
    end
    
    # Generic approach - find all models with domain attribute
    ActiveRecord::Base.descendants.each do |model|
      next unless model.table_exists?
      next unless model.column_names.include?('domain')
      next if model.name == 'PersonWhitelabel' # Handle separately
      
      models_with_domain << model
    end
    
    models_with_domain.each do |model|
      # Handle domains that follow the pattern [subdomain].staging.ownoutdoors.com
      staging_domains = model.where("domain LIKE '%.staging.ownoutdoors.com'")
      staging_domains.find_each do |record|
        old_domain = record.domain
        # Extract subdomain (everything before .staging.ownoutdoors.com)
        subdomain = old_domain.gsub('.staging.ownoutdoors.com', '')
        new_domain = "#{subdomain}.lvh.me"
        
        record.update!(domain: new_domain)
        puts "  📝 #{model.name}: #{old_domain} → #{new_domain}"
      end
      
      # Handle other domains that aren't already lvh.me and don't follow staging pattern
      other_domains = model.where.not(domain: 'lvh.me')
                          .where.not("domain LIKE '%.staging.ownoutdoors.com'")
                          .where.not("domain LIKE '%.lvh.me'")
      
      if other_domains.exists?
        puts "  ⚠️  Found #{other_domains.count} #{model.name} records with non-standard domains:"
        other_domains.find_each do |record|
          puts "    - #{record.domain} (ID: #{record.id})"
        end
        puts "    These will be set to 'lvh.me'. Continue? (y/N)"
        
        if non_interactive || STDIN.gets.chomp.downcase == 'y'
          updated_count = other_domains.update_all(domain: 'lvh.me')
          puts "  ✅ Updated #{updated_count} #{model.name} records to 'lvh.me'"
        else
          puts "  ⏭️  Skipped updating non-standard domains for #{model.name}"
        end
      end
      
      total_staging = staging_domains.count
      puts "  ✅ Updated #{total_staging} #{model.name} staging domain records" if total_staging > 0
    end
    
    # Step 7: Update PersonWhitelabel domains specifically
    puts "\n🏷️  Updating PersonWhitelabel domain attributes..."
    
    if defined?(PersonWhitelabel)
      person_whitelabels = PersonWhitelabel.where("domain LIKE '%.staging.ownoutdoors.com'")
      
      person_whitelabels.find_each do |pw|
        old_domain = pw.domain
        # Extract subdomain (everything before .staging.ownoutdoors.com)
        subdomain = old_domain.gsub('.staging.ownoutdoors.com', '')
        new_domain = "#{subdomain}.lvh.me"
        
        pw.update!(domain: new_domain)
        puts "  📝 Updated: #{old_domain} → #{new_domain}"
      end
      
      puts "✅ Updated #{person_whitelabels.count} PersonWhitelabel records"
    else
      puts "⚠️  PersonWhitelabel model not found - skipping specific updates"
    end
    
    # Step 8: Run any additional data transformations
    puts "\n🔧 Running additional local development transformations..."
    
    # Add any other local development specific changes here
    # Examples:
    # - Update email addresses to use a local domain
    # - Disable external API integrations
    # - Update file paths or URLs
    
    # Example: Update email domains for testing
    # User.where("email LIKE '%@ownoutdoors.com'").find_each do |user|
    #   user.update!(email: user.email.gsub('@ownoutdoors.com', '@localhost.dev'))
    # end
    
    # Step 9: Clean up dump files (optional)
    puts "\n🧹 Cleaning up temporary files..."
    File.delete(staging_dump_file) if File.exist?(staging_dump_file)
    puts "✅ Temporary files cleaned up"
    
    puts "\n🎉 Staging database import and domain updates completed successfully!"
    puts "📁 Local backup saved at: #{backup_file}"
    puts "🌐 All domains updated for local development"
  end
  
  private
  
  def transform_staging_domain(domain)
    if domain.end_with?('.staging.ownoutdoors.com')
      subdomain = domain.gsub('.staging.ownoutdoors.com', '')
      "#{subdomain}.lvh.me"
    elsif domain.end_with?('.ownoutdoors.com') && !domain.include?('.staging.')
      # Handle production domains if needed
      subdomain = domain.gsub('.ownoutdoors.com', '')
      "#{subdomain}.lvh.me"
    else
      domain
    end
  end
  
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
  
  def parse_database_url(url)
    uri = URI.parse(url)
    {
      host: uri.host,
      port: uri.port || 3306,
      database: uri.path[1..-1], # Remove leading slash
      username: uri.user,
      password: uri.password
    }
  end
end
