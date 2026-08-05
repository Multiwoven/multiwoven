# frozen_string_literal: true

module MultiwovenServer
  class EmbedCors
    PUBLIC_PATHS = [
      "/enterprise/api/v1/data_apps_runner",
      "/enterprise/api/v1/data_apps_runner.js",
      "/enterprise/api/v1/agentic_coding/analytics/track"
    ].freeze

    DATA_APP_PATH    = %r{\A/enterprise/api/v1/data_apps/(\d+)}
    AGENTIC_APP_PATH = %r{\A/enterprise/api/v1/agentic_coding/apps/(\d+)}

    ACAO         = "access-control-allow-origin"
    ACA_CREDS    = "access-control-allow-credentials"
    ACA_METHODS  = "access-control-allow-methods"
    ACA_HEADERS  = "access-control-allow-headers"
    ACA_MAX_AGE  = "access-control-max-age"
    VARY         = "vary"

    def self.start_refresher!
      return if bypass?

      Rails.logger.info("Starting embed origins refresher!!!")
      refresh!("initial")

      Thread.new do
        Thread.current.name = "embed-origins-refresh"
        Thread.current.report_on_exception = true
        loop do
          sleep(EmbedOrigins::Registry::REFRESH_INTERVAL_SECONDS)
          refresh!("periodic")
        end
      end
    end

    # Runs a Registry refresh with error logging so a transient DB blip
    # never kills the background thread.
    def self.refresh!(reason)
      EmbedOrigins::Registry.refresh!
    rescue StandardError => e
      Rails.logger.error("[EmbedCors] #{reason} refresh failed: #{e.class}: #{e.message}")
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) if self.class.bypass?

      return public_response(env) if PUBLIC_PATHS.include?(env["PATH_INFO"])

      workspace_id = resolve_workspace_id(env)
      return @app.call(env) if workspace_id.nil?

      raw_origin = env["HTTP_ORIGIN"]
      origin = EmbedOrigins::Registry.normalize_origin(raw_origin)
      allowlisted = origin.present? &&
                    EmbedOrigins::Registry.allowlist_for(workspace_id).include?(origin)

      return preflight_response(raw_origin, allowlisted, env) if env["REQUEST_METHOD"] == "OPTIONS"

      status, headers, body = @app.call(env)
      strip_acao!(headers)
      if allowlisted
        headers[ACAO]      = raw_origin
        headers[ACA_CREDS] = "true"
        headers[VARY]      = [headers[VARY], "Origin"].compact.join(", ")
      end
      [status, headers, body]
    end

    def self.bypass?
      ENV.fetch("EMBED_CORS_BYPASS", "true").casecmp("true").zero?
    end

    private

    def public_response(env)
      if env["REQUEST_METHOD"] == "OPTIONS"
        return [204, {
          ACAO => "*",
          ACA_METHODS => "GET, OPTIONS",
          ACA_HEADERS => env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"].to_s,
          ACA_MAX_AGE => "3600"
        }, []]
      end

      status, headers, body = @app.call(env)
      strip_acao!(headers)
      headers[ACAO] = "*"
      [status, headers, body]
    end

    def resolve_workspace_id(env)
      if (data_app_id = env["HTTP_DATA_APP_ID"]).present?
        EmbedOrigins::Registry.workspace_id_for_data_app(data_app_id)
      elsif (agentic_app_id = env["HTTP_AGENTIC_APP_ID"]).present?
        EmbedOrigins::Registry.workspace_id_for_agentic_app(agentic_app_id)
      elsif (m = env["PATH_INFO"].match(DATA_APP_PATH))
        EmbedOrigins::Registry.workspace_id_for_data_app(m[1])
      elsif (m = env["PATH_INFO"].match(AGENTIC_APP_PATH))
        EmbedOrigins::Registry.workspace_id_for_agentic_app(m[1])
      end
    end

    def preflight_response(origin, allowlisted, env)
      headers = {
        ACA_METHODS => "GET, POST, PUT, PATCH, DELETE, OPTIONS",
        ACA_HEADERS => env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"].to_s,
        ACA_MAX_AGE => "3600",
        VARY => "Origin"
      }
      if allowlisted
        headers[ACAO]      = origin
        headers[ACA_CREDS] = "true"
      end
      [204, headers, []]
    end

    # Strip any ACAO/credentials already set by an inner middleware
    # (typically Rack::Cors). In Rack 3, header names are case-sensitive at
    # the wire level, so we clear both cases to be safe.
    def strip_acao!(headers)
      headers.delete(ACAO)
      headers.delete("Access-Control-Allow-Origin")
      headers.delete(ACA_CREDS)
      headers.delete("Access-Control-Allow-Credentials")
    end
  end
end
