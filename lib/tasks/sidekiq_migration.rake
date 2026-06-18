namespace :jobs do
  desc 'Migrate existing delayed_job entries to Sidekiq'
  task migrate_to_sidekiq: :environment do
    require 'delayed_job_active_record'
    require 'sidekiq'
    
    # First, require all job files
    Dir[Rails.root.join('app/jobs/**/*.rb')].each { |file| require file }
    
    puts "Starting migration of delayed jobs to Sidekiq..."
    
    # Configure Sidekiq
    Sidekiq.configure_client do |config|
      config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
    end

    # Get all pending jobs
    total_jobs = Delayed::Job.count
    pending_jobs = Delayed::Job.where('attempts = 0')
    failed_jobs = Delayed::Job.where('attempts > 0')
    
    puts "Found #{total_jobs} total jobs"
    puts "#{pending_jobs.count} pending jobs"
    puts "#{failed_jobs.count} failed jobs"
    
    # Helper method to deserialize job
    def extract_job_data(handler)
      begin
        # Check if it's a PageLoadedJob struct
        if handler.include?('!ruby/struct:PageLoadedJob')
          # Parse the raw YAML to extract arguments
          yaml_lines = handler.split("\n")
          community_membership_id = yaml_lines.find { |l| l.include?('community_membership_id:') }&.split(':')&.last&.strip
          host = yaml_lines.find { |l| l.include?('host:') }&.split(':')&.last&.strip
          
          return {
            job_class: 'PageLoadedJob',
            args: [community_membership_id, host],
            queue: 'default'
          }
        end

        # Check if it's an AutomaticBookingConfirmationJob struct
        if handler.include?('!ruby/struct:AutomaticBookingConfirmationJob')
          # Parse the raw YAML to extract arguments
          yaml_lines = handler.split("\n")
          conversation_id = yaml_lines.find { |l| l.include?('conversation_id:') }&.split(':')&.last&.strip
          current_user_id = yaml_lines.find { |l| l.include?('current_user_id:') }&.split(':')&.last&.strip
          community_id = yaml_lines.find { |l| l.include?('community_id:') }&.split(':')&.last&.strip
          
          return {
            job_class: 'AutomaticBookingConfirmationJob',
            args: [conversation_id, current_user_id, community_id],
            queue: 'default'
          }
        end

        # Try to deserialize the job
        job = YAML.load(handler)
        
        # Check if job class exists
        job_class_name = job.class.name
        unless Object.const_defined?(job_class_name)
          puts "Skipping job with missing class: #{job_class_name}"
          return nil
        end

        # Extract arguments safely
        args = []
        if job.respond_to?(:args)
          args = job.args
        elsif job.respond_to?(:arguments)
          args = job.arguments
        elsif job.respond_to?(:members) && job.members.is_a?(Array)
          # Handle Struct-based jobs
          args = job.members.map { |member| job.send(member) }
        elsif job.respond_to?(:to_a)
          # Handle array-like objects
          args = job.to_a
        end

        # Extract queue name safely
        queue = 'default'
        if job.respond_to?(:queue_name)
          queue = job.queue_name
        elsif job.respond_to?(:queue)
          queue = job.queue
        elsif job.respond_to?(:queue_name=) && job.instance_variable_defined?(:@queue_name)
          queue = job.instance_variable_get(:@queue_name)
        end

        {
          job_class: job_class_name,
          args: args || [],
          queue: queue || 'default'
        }
      rescue NameError => e
        puts "Skipping job with missing class: #{e.message}"
        nil
      rescue => e
        puts "Error deserializing job: #{e.message}"
        nil
      end
    end
    
    # Migrate pending jobs
    puts "\nMigrating pending jobs..."
    migrated_count = 0
    skipped_count = 0
    error_count = 0
    
    pending_jobs.find_each do |dj|
      begin
        job_data = extract_job_data(dj.handler)
        unless job_data
          skipped_count += 1
          print "s"
          next
        end
        
        # Convert to ActiveJob format
        job_class = job_data[:job_class].constantize
        
        # Schedule in Sidekiq
        if dj.run_at
          job_class.set(wait_until: dj.run_at).perform_later(*job_data[:args])
        else
          job_class.perform_later(*job_data[:args])
        end
        
        # Mark as migrated
        dj.update_column(:handler, "[MIGRATED TO SIDEKIQ] #{dj.handler}")
        migrated_count += 1
        print "."
      rescue => e
        error_count += 1
        puts "\nError migrating job #{dj.id}: #{e.message}"
        print "e"
      end
    end
    
    puts "\n\nPending jobs migration summary:"
    puts "  Migrated: #{migrated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Errors: #{error_count}"
    
    # Skip failed jobs - only migrate pending jobs
    puts "\n\nSkipping failed jobs migration (only migrating pending jobs)"
    puts "Failed jobs count: #{failed_jobs.count}"
    puts "These will remain in delayed_jobs table for manual review if needed"
    
    puts "\n\nMigration completed!"
    puts "Total jobs processed: #{total_jobs}"
    puts "Pending jobs migrated: #{migrated_count}"
    puts "Pending jobs skipped: #{skipped_count}"
    puts "Pending jobs errors: #{error_count}"
    puts "Failed jobs (not migrated): #{failed_jobs.count}"
    puts "Remember to verify jobs in Sidekiq before dropping the delayed_jobs table"
  end
  
  desc 'Verify Sidekiq migration'
  task verify_migration: :environment do
    require 'delayed_job_active_record'
    require 'sidekiq'
    
    puts "Verifying migration status..."
    
    # Check remaining non-migrated jobs
    remaining = Delayed::Job.where("handler NOT LIKE '[MIGRATED TO SIDEKIQ]%'").count
    migrated = Delayed::Job.where("handler LIKE '[MIGRATED TO SIDEKIQ]%'").count
    
    puts "Migration Status:"
    puts "----------------"
    puts "Total jobs in delayed_jobs: #{Delayed::Job.count}"
    puts "Jobs migrated to Sidekiq: #{migrated}"
    puts "Jobs not yet migrated: #{remaining}"
    
    if remaining.zero?
      puts "\n✅ All jobs have been migrated!"
      puts "You can now safely run the migration to drop the delayed_jobs table"
    else
      puts "\n⚠️  There are still #{remaining} jobs that haven't been migrated!"
      puts "Please run 'rake jobs:migrate_to_sidekiq' to migrate remaining jobs"
    end
    
    # Check Sidekiq queues
    Sidekiq.redis do |conn|
      queues = conn.smembers('queues')
      puts "\nSidekiq Queues:"
      puts "--------------"
      queues.each do |queue|
        size = conn.llen("queue:#{queue}")
        puts "#{queue}: #{size} jobs"
      end
    end
  end
end 