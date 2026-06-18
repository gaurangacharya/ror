# Sidekiq configuration for ActiveJob integration
# This replaces the delayed_job configuration

require 'sidekiq'
require 'sidekiq/web'

# Configure Sidekiq client and server
Sidekiq.configure_server do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    network_timeout: 5
  }
  
  # Set up logging
  config.logger.level = Logger::INFO
  
  # Configure error handling
  config.error_handlers << proc do |ex, ctx_hash|
    Rails.logger.error "Sidekiq error: #{ex.message}"
    Rails.logger.error ex.backtrace.join("\n")
    
    # Sentry integration is handled automatically by sentry-sidekiq gem
  end

  # Remove TwilioSmsJob from any specific queues if configured
  config.queues = config.queues.reject { |q| q.include?('twilio') }
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    network_timeout: 5
  }
end

# Configure ActiveJob to use Sidekiq
Rails.application.config.active_job.queue_adapter = :sidekiq

# Set default queue names for ActiveJob
Rails.application.config.active_job.queue_name_prefix = Rails.env.production? ? 'production' : Rails.env

# Configure default job options for ActiveJob
# This maintains compatibility with the previous delayed_job priority system
ActiveJob::Base.queue_adapter = :sidekiq
ActiveJob::Base.default_queue_name = 'default'

# Web UI authentication (for production environments)
if Rails.env.production?
  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    # Use environment variables for authentication
    [user, password] == [ENV['SIDEKIQ_USERNAME'], ENV['SIDEKIQ_PASSWORD']]
  end
end 