class TripadvisorService
  CURRENCY = 'USD'
  LANGUAGE = 'en'
  KEY = APP_CONFIG.tripadvisor_key
  BASE_URI = 'https://api.content.tripadvisor.com/api/v1/location'

  attr_reader :location_id, :logger

  def initialize(location_id:, logger:)
    @location_id = location_id
    @logger = logger
  end

  def info
    return nil unless location_id.present?

    record = TripadvisorResponse.where(location_id: location_id).first_or_initialize
    if record.outdated?
      record.body = data
    end

    record.save

    record.body.present? && !record.body['error'] ? record.body : nil
  end

  private

  def data
    reponse = Net::HTTP.get(uri)
    JSON.parse(reponse)
  rescue => e
    logger.error("Could not fetch location info: #{e.inspect} #{e.backtrace.join("\n")}")
    nil
  end

  def uri
    URI("#{BASE_URI}/#{location_id}/details?#{query}")
  end

  def query
    URI.encode_www_form([['currency', CURRENCY], ['language', LANGUAGE], ['key', KEY]])
  end
end
