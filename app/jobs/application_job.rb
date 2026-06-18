class ApplicationJob < ActiveJob::Base
  include DelayedSentryNotification

  # Configure default queue and priority
  queue_as :default
  
  # Configure retry behavior with more granular control
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  retry_on ActiveRecord::RecordNotFound, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::StaleObjectError, wait: 1.second, attempts: 3
  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 10
  
  # Discard jobs that fail due to these errors
  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound do |job, error|
    Rails.logger.error("Discarding job due to missing record: #{error.message}")
  end
  
  around_perform :handle_job_errors

  private

  def handle_job_errors
    begin
      yield
    rescue StandardError => e
      # Log error details with more context
      Rails.logger.error({
        job_class: self.class.name,
        job_id: job_id,
        arguments: arguments.inspect,
        error_class: e.class.name,
        error_message: e.message,
        backtrace: e.backtrace&.first(5),
      }.to_json)
      
      # Notify error tracking service if configured
      if defined?(Sentry) && APP_CONFIG.use_sentry && Sentry.initialized?
        Sentry.with_scope do |scope|
          scope.set_context("job", {
            job_class: self.class.name,
            job_id: job_id,
            arguments: arguments
          })
          scope.set_tag("component", self.class.name)
          scope.set_tag("action", "perform")
          Sentry.capture_exception(e)
        end
      end
      
      raise e
    end
  end

  def set_job_context
    Thread.current[:job_id] = job_id
    Thread.current[:job_class] = self.class.name
    yield
  ensure
    Thread.current[:job_id] = nil
    Thread.current[:job_class] = nil
  end
end 