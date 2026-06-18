module DelayedSentryNotification

  # Notify Sentry in case of errors
  def error(job, exception)
    if APP_CONFIG.use_sentry && defined?(Sentry) && Sentry.initialized?
      Sentry.with_scope do |scope|
        scope.set_context("delayed_job", {
          job_class: job.class.name,
          job_id: job.job_id,
          arguments: job.arguments
        })
        scope.set_tag("component", "delayed_job")
        Sentry.capture_exception(exception)
      end
    end
  end

end
