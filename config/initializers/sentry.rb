if APP_CONFIG.use_sentry
  require 'sentry-sidekiq'
  
  Sentry.init do |config|
    config.dsn = APP_CONFIG.sentry_dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    
    config.rails.report_rescued_exceptions = true
    
    config.environment = Rails.env
    
    config.release = `git rev-parse HEAD`.chomp
    
    config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0
    
    config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0

    config.send_default_pii = true
    
    config.before_send = lambda do |event, hint|
      if event.request&.data
        event.request.data = event.request.data.except(*Rails.application.config.filter_parameters)
      end
      
      errors_to_ignore = [
        "AbstractController::ActionNotFound",
        "ActiveRecord::RecordNotFound", 
        "ActionController::RoutingError",
        "ActionController::UnknownAction",
        "PeopleController::PersonDeleted",
        "PeopleController::PersonBanned",
        "ListingsController::ListingDeleted"
      ]
      
      if event.exception&.any? { |exception| errors_to_ignore.include?(exception.type) }
        nil
      else
        event
      end
    end
    
    config.before_send_transaction = lambda do |event, hint|
      event.set_context("application", {
        name: "OwnOutdoors",
        version: Rails.application.class.module_parent_name.constantize::VERSION
      })
      event
    end
  end
end
