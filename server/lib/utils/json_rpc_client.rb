# frozen_string_literal: true

module Utils
  class JsonRpcClient < HttpClient
    DEFAULT_TIMEOUT = 30
    ALLOWED_SCHEMES = %w[http https].freeze

    def self.execute_rpc(url:, method:, params: {}, headers: {}, config: {})
      validate_uri_scheme!(url)
      envelope = build_jsonrpc_envelope(method, params)
      result = post(
        base_url: url,
        headers: rpc_headers(headers),
        body: envelope,
        config: translate_config(config)
      )
      wrap_result(result, validate_hash: true)
    rescue URI::InvalidURIError => e
      error_response(e)
    end

    def self.execute_get(url:, headers: {}, config: {})
      validate_uri_scheme!(url)
      result = get(
        base_url: url,
        headers: rpc_headers(headers),
        config: translate_config(config)
      )
      wrap_result(result)
    rescue URI::InvalidURIError => e
      error_response(e)
    end

    def self.handle_response(response)
      body = parse_response_body(response)
      return body if response.code.to_i.between?(200, 299)

      body["error"] ||= { "message" => "HTTP request failed with status #{response.code}" }
      body
    end

    def self.post(base_url:, headers: {}, body: nil, config: {})
      super
    rescue RuntimeError => e
      raise e.cause || e
    end

    def self.get(base_url:, headers: {}, config: {})
      super
    rescue RuntimeError => e
      raise e.cause || e
    end

    def self.build_http_client(uri, timeout: DEFAULT_TIMEOUT, read_timeout: nil)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = timeout
      http.read_timeout = read_timeout || timeout
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development? || Rails.env.test?
      http
    end

    def self.build_post_request(uri, method, params, headers: {}, id: nil)
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      headers.each { |k, v| request[k.to_s] = v }
      request.body = build_jsonrpc_envelope(method, params, id:).to_json
      request
    end

    def self.build_jsonrpc_envelope(method, params = {}, id: nil)
      {
        jsonrpc: "2.0",
        id: id || rand(1..2_147_483_647),
        method:,
        params:
      }
    end

    def self.parse_jsonrpc_response(response, body: nil)
      raw = body || response.body
      parsed = JSON.parse(raw.to_s)
      unless parsed.is_a?(Hash)
        return { success: false, status: response.code, raw:,
                 body: { "error" => { "message" => "Invalid JSON-RPC response: expected object" } } }
      end

      { success: response.is_a?(Net::HTTPSuccess) && !parsed.key?("error"),
        status: response.code, raw:, body: parsed }
    rescue JSON::ParserError
      { success: false, status: response.code, raw:,
        body: { "error" => { "message" => "Invalid JSON response" } } }
    end

    def self.parse_response(response)
      body = parse_response_body(response)
      { success: response.is_a?(Net::HTTPSuccess), body: }
    end

    def self.validate_uri_scheme!(url)
      return if ALLOWED_SCHEMES.include?(URI.parse(url).scheme)

      raise URI::InvalidURIError, "Unsupported URI scheme (only http/https allowed)"
    end

    def self.rpc_headers(custom = {})
      { "Accept" => "application/json" }.merge(custom)
    end

    def self.translate_config(config)
      t = config.fetch(:timeout, DEFAULT_TIMEOUT)
      { timeout: config[:read_timeout] || t, open_timeout: t }
    end

    def self.parse_response_body(response)
      return {} if response.body.blank?

      parsed = JSON.parse(response.body)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError
      {}
    end

    def self.wrap_result(result, validate_hash: false)
      if validate_hash && !result.is_a?(Hash)
        return { success: false, body: { "error" => { "message" => "Invalid JSON-RPC response: expected object" } } }
      end

      { success: !(result.is_a?(Hash) && result.key?("error")), body: result }
    end

    def self.error_response(error)
      { success: false, body: { "error" => { "message" => "Transport error: #{error.message}" } } }
    end

    private_class_method :validate_uri_scheme!, :rpc_headers, :translate_config,
                         :parse_response_body, :wrap_result, :error_response
  end
end
