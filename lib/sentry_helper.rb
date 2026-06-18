# SentryHelper - Enhanced error reporting for FareHarbor integration
class SentryHelper
  class << self
    def report_fareharbor_error(exception, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        # Set context for FareHarbor errors
        scope.set_tag("component", "fareharbor")
        scope.set_tag("error_type", exception.class.name)
        scope.set_level("error")
        
        # Add custom context
        version = begin
          Rails.application.class.parent_name.constantize::VERSION
        rescue
          "unknown"
        end
        
        scope.set_context("fareharbor", {
          timestamp: Time.current.iso8601,
          environment: Rails.env,
          version: version
        }.merge(context))
        
        # Add user context if available
        if context[:company_shortname]
          scope.set_user(id: context[:company_shortname], username: context[:company_shortname])
        end
        
        # Add extra context
        scope.set_extra("fareharbor_context", context)
        
        # Capture the exception
        Sentry.capture_exception(exception)
      end
    end

    def report_fareharbor_warning(message, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tag("component", "fareharbor")
        scope.set_tag("warning_type", "api_warning")
        scope.set_level("warning")
        
        scope.set_context("fareharbor_warning", {
          message: message,
          timestamp: Time.current.iso8601,
          environment: Rails.env
        }.merge(context))
        
        Sentry.capture_message(message)
      end
    end

    def report_fareharbor_api_error(api_error, company_shortname, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tag("component", "fareharbor")
        scope.set_tag("error_type", "api_error")
        scope.set_tag("company", company_shortname)
        scope.set_level("error")
        
        scope.set_context("fareharbor_api_error", {
          company_shortname: company_shortname,
          api_error: api_error,
          timestamp: Time.current.iso8601,
          environment: Rails.env
        }.merge(context))
        
        # Create a custom exception for API errors
        exception = StandardError.new("FareHarbor API Error: #{api_error}")
        exception.define_singleton_method(:backtrace) { caller }
        
        Sentry.capture_exception(exception)
      end
    end

    def report_fareharbor_import_stats(stats, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tag("component", "fareharbor")
        scope.set_tag("event_type", "import_stats")
        scope.set_level("info")
        
        scope.set_context("fareharbor_import_stats", {
          stats: stats,
          timestamp: Time.current.iso8601,
          environment: Rails.env
        }.merge(context))
        
        Sentry.capture_message("FareHarbor Import Statistics", level: "info")
      end
    end

    def report_fareharbor_company_error(company_shortname, error_message, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tag("component", "fareharbor")
        scope.set_tag("error_type", "company_error")
        scope.set_tag("company", company_shortname)
        scope.set_level("error")
        
        scope.set_context("fareharbor_company_error", {
          company_shortname: company_shortname,
          error_message: error_message,
          timestamp: Time.current.iso8601,
          environment: Rails.env
        }.merge(context))
        
        exception = StandardError.new("FareHarbor Company Error: #{error_message}")
        exception.define_singleton_method(:backtrace) { caller }
        
        Sentry.capture_exception(exception)
      end
    end

    def report_fareharbor_item_error(company_shortname, item_id, error_message, context = {})
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tag("component", "fareharbor")
        scope.set_tag("error_type", "item_error")
        scope.set_tag("company", company_shortname)
        scope.set_tag("item_id", item_id.to_s)
        scope.set_level("error")
        
        scope.set_context("fareharbor_item_error", {
          company_shortname: company_shortname,
          item_id: item_id,
          error_message: error_message,
          timestamp: Time.current.iso8601,
          environment: Rails.env
        }.merge(context))
        
        exception = StandardError.new("FareHarbor Item Error: #{error_message}")
        exception.define_singleton_method(:backtrace) { caller }
        
        Sentry.capture_exception(exception)
      end
    end

    private

    def sentry_available?
      defined?(Sentry) && APP_CONFIG&.use_sentry && Sentry.initialized?
    end
  end
end
