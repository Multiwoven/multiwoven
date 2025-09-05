# frozen_string_literal: true

module Utils
  class HttpClient
    def self.post(base_url:, headers: {}, body: nil, config: {})
      config ||= {}
      timeout       = config.fetch(:timeout, 60)
      open_timeout  = config.fetch(:open_timeout, 20)
      uri = URI.parse(base_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.read_timeout = timeout
      http.open_timeout = open_timeout

      request = Net::HTTP::Post.new(uri.request_uri)

      # Set default headers
      request["Content-Type"] = "application/json"

      # Add custom headers
      headers.each { |key, value| request[key] = value }

      # Set body
      request.body = body.is_a?(Hash) ? body.to_json : body

      response = http.request(request)
      handle_response(response)
    rescue StandardError => e
      raise "HTTP request failed: #{e.message}"
    end

    def self.handle_response(response)
      case response.code
      when "200"
        JSON.parse(response.body)
      else
        error_message = "HTTP request failed with status #{response.code}"
        error_message += ": #{response.body}" if response.body.present?
        raise error_message
      end
    end
  end
end
