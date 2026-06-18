class HealthCheck
  def initialize(app)
    @app = app
  end

  def call(env)
    req = ::Rack::Request.new(env)

    if req.fullpath == "/_health"
      health_status = check_health
      status_code = health_status[:healthy] ? 200 : 503
      [status_code, {'Content-Type' => 'application/json'}, [health_status.to_json]]
    else
      @app.call(env)
    end
  end

  private

  def check_health
    health_data = {
      healthy: true,
      timestamp: Time.current.iso8601,
      services: {}
    }

    # Check database connectivity
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      health_data[:services][:database] = { status: 'healthy' }
    rescue => e
      health_data[:healthy] = false
      health_data[:services][:database] = { status: 'unhealthy', error: e.message }
    end

    # Check Redis/Sidekiq connectivity
    begin
      if defined?(Sidekiq)
        redis_info = Sidekiq.redis { |conn| conn.ping }
        sidekiq_stats = Sidekiq::Stats.new
        health_data[:services][:sidekiq] = {
          status: 'healthy',
          redis_ping: redis_info,
          processed: sidekiq_stats.processed,
          failed: sidekiq_stats.failed,
          enqueued: sidekiq_stats.enqueued,
          scheduled: sidekiq_stats.scheduled_size,
          retry: sidekiq_stats.retry_size,
          dead: sidekiq_stats.dead_size
        }
      else
        health_data[:services][:sidekiq] = { status: 'not_configured' }
      end
    rescue => e
      health_data[:healthy] = false
      health_data[:services][:sidekiq] = { status: 'unhealthy', error: e.message }
    end

    health_data
  end
end
