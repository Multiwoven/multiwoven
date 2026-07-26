# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    # Shared OAuth2 client_credentials flow. Include in a connector client to:
    #   * inject `Authorization: Bearer <token>` when connection_config[:auth_type]
    #     is `oauth_client_credentials`
    #   * cache the token in the connector's `configuration` JSON and refresh it
    #     shortly before expiry
    #
    # The including class is expected to set `@connector_instance` (an object
    # responding to `configuration` and `update!`) before making requests that
    # should benefit from the cache. Without it, a fresh token is fetched every
    # call — safe but wasteful.
    module OauthClientCredentials
      AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS = "oauth_client_credentials"
      # Refresh access tokens this many seconds before their advertised expiry,
      # so a token that expires mid-request doesn't leave the connector.
      TOKEN_EXPIRY_BUFFER_SECONDS = 300

      def build_headers(connection_config)
        headers = (connection_config[:headers] || {}).to_h.dup
        return headers unless connection_config[:auth_type] == AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS

        headers["Authorization"] = "Bearer #{ensure_oauth_token(connection_config)}"
        headers
      end

      def ensure_oauth_token(connection_config)
        cached = cached_oauth_token
        return cached if cached

        fetch_and_cache_oauth_token(connection_config)
      end

      private

      def cached_oauth_token
        config = connector_configuration
        return nil unless config

        token = config["oauth_access_token"]
        expires_at = config["oauth_expires_at"]
        return nil if token.nil? || token.to_s.empty? || expires_at.nil?
        return nil if Time.parse(expires_at.to_s) <= Time.now + TOKEN_EXPIRY_BUFFER_SECONDS

        token
      rescue ArgumentError, TypeError
        nil
      end

      def fetch_and_cache_oauth_token(connection_config)
        token_url = connection_config[:token_url]
        client_id = connection_config[:client_id]
        client_secret = connection_config[:client_secret]
        raise ArgumentError, "OAuth token_url, client_id, and client_secret are required when auth_type is #{AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS}" if token_url.to_s.empty? || client_id.to_s.empty? || client_secret.to_s.empty?

        response = post_token_request(token_url, client_id, client_secret, connection_config[:scope])
        raise "OAuth token request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        access_token = body["access_token"]
        raise "OAuth token response missing 'access_token'" if access_token.to_s.empty?

        expires_in = (body["expires_in"] || 3600).to_i
        persist_oauth_token(access_token, Time.now + expires_in)
        access_token
      end

      def post_token_request(token_url, client_id, client_secret, scope)
        uri = URI(token_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

        form = {
          "grant_type" => "client_credentials",
          "client_id" => client_id,
          "client_secret" => client_secret
        }
        form["scope"] = scope unless scope.to_s.empty?

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/x-www-form-urlencoded"
        request.body = URI.encode_www_form(form)
        http.request(request)
      end

      def persist_oauth_token(access_token, expires_at)
        return unless @connector_instance.respond_to?(:update!)

        base = connector_configuration || {}
        new_config = base.merge(
          "oauth_access_token" => access_token,
          "oauth_expires_at" => expires_at.iso8601
        )
        @connector_instance.update!(configuration: new_config)
      end

      def connector_configuration
        return nil unless @connector_instance.respond_to?(:configuration)

        cfg = @connector_instance.configuration
        cfg.is_a?(Hash) ? cfg : nil
      end
    end
  end
end
