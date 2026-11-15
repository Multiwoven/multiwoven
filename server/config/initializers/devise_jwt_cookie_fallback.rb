# frozen_string_literal: true

# warden-jwt_auth 0.12 exposes its Warden strategy at `Warden::JWTAuth::Strategy`
# (singular) — see gems/warden-jwt_auth/lib/warden/jwt_auth/strategy.rb. The
# base class only reads the JWT from the `Authorization: Bearer` header via
# HeaderParser.from_env. Subclass it and override `token` to fall back to the
# `authToken` cookie when the header is absent, then re-register under the
# same `:jwt` key so devise-jwt picks up our strategy.

require "warden/jwt_auth"
require "warden/jwt_auth/strategy"

module Warden
  module JWTAuth
    class HeaderOrCookieStrategy < Strategy
      def token
        @token ||= header_token || cookie_token
      end

      private

      def header_token
        HeaderParser.from_env(env)
      end

      def cookie_token
        cookie_header = env["HTTP_COOKIE"]
        return nil if cookie_header.blank?

        Rack::Utils.parse_cookies_header(cookie_header)[AuthCookies::AUTH_COOKIE_NAME].presence
      end
    end
  end
end

Warden::Strategies.add(:jwt, Warden::JWTAuth::HeaderOrCookieStrategy)
