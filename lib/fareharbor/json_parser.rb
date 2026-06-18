module Fareharbor
  class JSONParser < Faraday::Response::Middleware
    def parse(body)
      json = MultiJson.load(body, symbolize_keys: true)
      {
        data:     json[json.keys.first],
        metadata: {},
        errors:   []
      }
    rescue MultiJson::ParseError => exception
      { errors: [exception.cause] }
    end
  end
end
