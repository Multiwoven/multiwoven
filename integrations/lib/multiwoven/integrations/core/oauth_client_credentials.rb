# frozen_string_literal: true

require "jwt"
require "openssl"
require "securerandom"

module Multiwoven
  module Integrations::Core
    # Shared OAuth2 client_credentials flows. Include in a connector client to:
    #   * inject `Authorization: Bearer <token>` when connection_config[:auth_type]
    #     is `oauth_client_credentials` or `oauth_private_key_jwt`
    #   * cache the token in the connector's `configuration` JSON and refresh it
    #     shortly before expiry
    #
    # `oauth_client_credentials` — classic client_id + client_secret.
    # `oauth_private_key_jwt` — client_assertion JWT signed with an RSA private
    #   key (Epic Backend Services / SMART confidential asymmetric).
    #
    # The including class is expected to set `@connector_instance` (an object
    # responding to `configuration` and `update!`) before making requests that
    # should benefit from the cache. Without it, a fresh token is fetched every
    # call — safe but wasteful.
    module OauthClientCredentials
      AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS = "oauth_client_credentials"
      AUTH_TYPE_PRIVATE_KEY_JWT = "oauth_private_key_jwt"
      OAUTH_AUTH_TYPES = [AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS, AUTH_TYPE_PRIVATE_KEY_JWT].freeze

      CLIENT_ASSERTION_TYPE = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
      # Epic / SMART Backend Services require RS384; RS256 is kept for other IdPs.
      DEFAULT_JWT_ALGORITHM = "RS384"
      ALLOWED_JWT_ALGORITHMS = %w[RS384 RS256].freeze
      JWT_ASSERTION_LIFETIME_SECONDS = 300
      # Refresh access tokens this many seconds before their advertised expiry,
      # so a token that expires mid-request doesn't leave the connector.
      TOKEN_EXPIRY_BUFFER_SECONDS = 300

      def build_headers(connection_config)
        headers = (connection_config[:headers] || {}).to_h.dup
        return headers unless oauth_auth_type?(connection_config[:auth_type])

        headers["Authorization"] = "Bearer #{ensure_oauth_token(connection_config)}"
        headers
      end

      def ensure_oauth_token(connection_config)
        cached = cached_oauth_token
        return cached if cached

        fetch_and_cache_oauth_token(connection_config)
      end

      private

      def oauth_auth_type?(auth_type)
        OAUTH_AUTH_TYPES.include?(auth_type)
      end

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
        response = case connection_config[:auth_type]
                   when AUTH_TYPE_PRIVATE_KEY_JWT
                     post_private_key_jwt_token_request(connection_config)
                   else
                     post_client_secret_token_request(connection_config)
                   end
        raise "OAuth token request failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        access_token = body["access_token"]
        raise "OAuth token response missing 'access_token'" if access_token.to_s.empty?

        expires_in = (body["expires_in"] || 3600).to_i
        persist_oauth_token(access_token, Time.now + expires_in)
        access_token
      end

      def post_client_secret_token_request(connection_config)
        token_url = connection_config[:token_url]
        client_id = connection_config[:client_id]
        client_secret = connection_config[:client_secret]
        if token_url.to_s.empty? || client_id.to_s.empty? || client_secret.to_s.empty?
          raise ArgumentError,
                "OAuth token_url, client_id, and client_secret are required when auth_type is " \
                "#{AUTH_TYPE_OAUTH_CLIENT_CREDENTIALS}"
        end

        form = {
          "grant_type" => "client_credentials",
          "client_id" => client_id,
          "client_secret" => client_secret
        }
        form["scope"] = connection_config[:scope] unless connection_config[:scope].to_s.empty?
        post_form(token_url, form)
      end

      def post_private_key_jwt_token_request(connection_config)
        token_url = connection_config[:token_url]
        client_id = connection_config[:client_id]
        private_key = connection_config[:private_key]
        kid = connection_config[:kid]
        if token_url.to_s.empty? || client_id.to_s.empty? || private_key.to_s.empty? || kid.to_s.empty?
          raise ArgumentError,
                "OAuth token_url, client_id, private_key, and kid are required when auth_type is " \
                "#{AUTH_TYPE_PRIVATE_KEY_JWT}"
        end

        assertion = build_client_assertion(connection_config)
        form = {
          "grant_type" => "client_credentials",
          "client_id" => client_id,
          "client_assertion_type" => CLIENT_ASSERTION_TYPE,
          "client_assertion" => assertion
        }
        form["scope"] = connection_config[:scope] unless connection_config[:scope].to_s.empty?
        post_form(token_url, form)
      end

      def build_client_assertion(connection_config)
        token_url = connection_config[:token_url].to_s
        client_id = connection_config[:client_id].to_s
        audience = connection_config[:audience].to_s
        audience = token_url if audience.empty?
        algorithm = resolve_jwt_algorithm(connection_config[:algorithm])
        kid = connection_config[:kid].to_s

        now = Time.now.to_i
        payload = {
          "iss" => client_id,
          "sub" => client_id,
          "aud" => audience,
          "jti" => SecureRandom.uuid,
          "iat" => now,
          "nbf" => now,
          "exp" => now + JWT_ASSERTION_LIFETIME_SECONDS
        }
        headers = { "typ" => "JWT", "kid" => kid }

        key = load_private_key(connection_config[:private_key])
        JWT.encode(payload, key, algorithm, headers)
      end

      def resolve_jwt_algorithm(algorithm)
        algorithm = algorithm.to_s
        algorithm = DEFAULT_JWT_ALGORITHM if algorithm.empty?
        return algorithm if ALLOWED_JWT_ALGORITHMS.include?(algorithm)

        raise ArgumentError,
              "Unsupported OAuth JWT algorithm '#{algorithm}'. " \
              "Allowed: #{ALLOWED_JWT_ALGORITHMS.join(", ")}"
      end

      def load_private_key(private_key)
        key = begin
          OpenSSL::PKey.read(normalize_pem(private_key))
        rescue OpenSSL::PKey::PKeyError, ArgumentError => e
          raise ArgumentError, "Invalid OAuth private_key: #{e.message}"
        end

        raise ArgumentError, "OAuth private_key must be an RSA private key in PEM format" unless key.is_a?(OpenSSL::PKey::RSA) && key.private?

        key
      end

      # JSON/UI fields often store PEMs with escaped newlines ("\n") or as a single
      # line with spaces. OpenSSL::PKey.read rejects both; normalize before parsing.
      def normalize_pem(private_key)
        pem = private_key.to_s.strip
        pem = pem.gsub('\r\n', "\n").gsub('\n', "\n").gsub('\r', "\n")

        return pem if pem.include?("\n")

        labels = [
          "RSA PRIVATE KEY",
          "PRIVATE KEY"
        ]

        labels.each do |label|
          begin_marker = "-----BEGIN #{label}-----"
          end_marker = "-----END #{label}-----"

          next unless pem.start_with?(begin_marker) && pem.end_with?(end_marker)

          body = pem.delete_prefix(begin_marker)
                    .delete_suffix(end_marker)
                    .delete(" ")

          return "#{begin_marker}\n#{body.scan(/.{1,64}/).join("\n")}\n#{end_marker}\n"
        end

        pem
      end

      def post_form(token_url, form)
        uri = URI(token_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")

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
