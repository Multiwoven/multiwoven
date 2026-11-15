# frozen_string_literal: true

require "active_support/security_utils"

module MultiwovenServer
  # Double-submit CSRF guard for cookie-authenticated requests.
  # Header-authenticated (Authorization: Bearer) callers are bypassed — the
  # attack model relies on the browser auto-attaching a cookie.
  class CsrfGuard
    SAFE_METHODS = %w[GET HEAD OPTIONS].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) if bypass?
      return @app.call(env) if SAFE_METHODS.include?(env["REQUEST_METHOD"])

      cookies = Rack::Utils.parse_cookies_header(env["HTTP_COOKIE"].to_s)
      return @app.call(env) if cookies[AuthCookies::AUTH_COOKIE_NAME].blank?

      header_token = env["HTTP_X_CSRF_TOKEN"].to_s
      cookie_token = cookies[AuthCookies::CSRF_COOKIE_NAME].to_s

      if header_token.empty? ||
         cookie_token.empty? ||
         !ActiveSupport::SecurityUtils.secure_compare(header_token, cookie_token)
        return [403, { "Content-Type" => "text/plain" }, ["CSRF token mismatch"]]
      end

      @app.call(env)
    end

    private

    # Backward-compat kill-switch. Default `"true"` keeps CSRF enforcement OFF so
    # this middleware ships without breaking existing environments. Flip to
    # `"false"` per environment once the FE cutover (X-CSRF-Token header) is in
    # place to activate enforcement.
    def bypass?
      ENV.fetch("CSRF_BYPASS", "true").casecmp("true").zero?
    end
  end
end
