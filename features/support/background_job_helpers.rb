module BackgroundJobHelpers

  def process_jobs
    # Process all enqueued jobs
    ActiveJob::Base.queue_adapter = :test
    performed_jobs = ActiveJob::Base.queue_adapter.performed_jobs
    enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
    
    # Perform all enqueued jobs
    enqueued_jobs.each do |job|
      job_class = job[:job].constantize
      job_class.perform_now(*job[:args])
    end

    # Clear the job queues
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    # Raise error if any jobs failed
    if performed_jobs.any? { |job| job[:exception] }
      raise "Background job failed"
    end
  end
end

World(BackgroundJobHelpers)
