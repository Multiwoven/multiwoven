# frozen_string_literal: true

module AuthCookies
  extend ActiveSupport::Concern

  # Public string constants — shared with the CSRF middleware (Rack-level, needs
  # strings) and the JWT cookie-fallback strategy. Rails' `cookies` jar accepts
  # both symbols and strings, so controllers can index either way.
  AUTH_COOKIE_NAME = Rails.env.production? ? "__Host-authToken" : "authTokenHttp"
  CSRF_COOKIE_NAME = "csrf-token"
  COOKIE_TTL = 3.hours

  def render_auth_token(token, status:)
    render json: {
      data: {
        type: "token",
        id: SecureRandom.uuid,
        attributes: json_jwt? ? { token: } : {}
      }
    }, status:
  end

  private

  def write_auth_cookie(jwt)
    cookies[AUTH_COOKIE_NAME] = {
      value: jwt,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      path: "/",
      expires: COOKIE_TTL.from_now
    }
  end

  def write_csrf_cookie
    cookies[CSRF_COOKIE_NAME] = {
      value: SecureRandom.hex(32),
      httponly: false,
      secure: Rails.env.production?,
      same_site: :lax,
      path: "/",
      expires: COOKIE_TTL.from_now
    }
  end

  def clear_all_auth_cookies
    cookies.delete(AUTH_COOKIE_NAME, path: "/")
    cookies.delete(CSRF_COOKIE_NAME, path: "/")
  end

  def json_jwt?
    return true if request.headers["X-App-Context"] == "embed"

    ENV.fetch("BEARER_TOKEN_AUTH", "true").casecmp("true").zero?
  end
end
