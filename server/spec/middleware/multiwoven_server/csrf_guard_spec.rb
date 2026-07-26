# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/middleware/multiwoven_server/csrf_guard"

RSpec.describe MultiwovenServer::CsrfGuard do
  let(:inner_response) { [200, { "Content-Type" => "text/plain" }, ["ok"]] }
  let(:inner_app) { ->(_env) { inner_response } }
  subject(:middleware) { described_class.new(inner_app) }

  def env_for(method:, cookie: nil, csrf_header: nil)
    env = Rack::MockRequest.env_for("/", method:)
    env["HTTP_COOKIE"] = cookie if cookie
    env["HTTP_X_CSRF_TOKEN"] = csrf_header if csrf_header
    env
  end

  # All enforcement cases below need CSRF_BYPASS off. Wrap them with a shared
  # env-var override so the tests don't depend on process env leaking in.
  around(:each, csrf_enforced: true) do |example|
    original = ENV["CSRF_BYPASS"]
    ENV["CSRF_BYPASS"] = "false"
    example.run
  ensure
    ENV["CSRF_BYPASS"] = original
  end

  describe "CSRF_BYPASS flag" do
    it "passes any request through when the flag is unset (default: bypass on)" do
      original = ENV["CSRF_BYPASS"]
      ENV.delete("CSRF_BYPASS")
      begin
        status, = middleware.call(
          env_for(method: "POST", cookie: "#{AuthCookies::AUTH_COOKIE_NAME}=jwt")
        )
        expect(status).to eq(200)
      ensure
        ENV["CSRF_BYPASS"] = original
      end
    end

    it "passes any request through when the flag is explicitly 'true'" do
      original = ENV["CSRF_BYPASS"]
      ENV["CSRF_BYPASS"] = "true"
      begin
        status, = middleware.call(
          env_for(method: "POST", cookie: "#{AuthCookies::AUTH_COOKIE_NAME}=jwt")
        )
        expect(status).to eq(200)
      ensure
        ENV["CSRF_BYPASS"] = original
      end
    end

    it "matches 'true' case-insensitively", :aggregate_failures do
      original = ENV["CSRF_BYPASS"]
      %w[TRUE True tRuE].each do |value|
        ENV["CSRF_BYPASS"] = value
        status, = middleware.call(
          env_for(method: "POST", cookie: "#{AuthCookies::AUTH_COOKIE_NAME}=jwt")
        )
        expect(status).to eq(200), "expected bypass for CSRF_BYPASS=#{value}"
      end
    ensure
      ENV["CSRF_BYPASS"] = original
    end

    it "enforces when set to anything other than 'true' (e.g. 'false')", csrf_enforced: true do
      status, = middleware.call(
        env_for(method: "POST", cookie: "#{AuthCookies::AUTH_COOKIE_NAME}=jwt")
      )
      expect(status).to eq(403)
    end
  end

  describe "safe methods", csrf_enforced: true do
    %w[GET HEAD OPTIONS].each do |method|
      it "passes #{method} requests through without a CSRF check" do
        status, = middleware.call(
          env_for(method:, cookie: "#{AuthCookies::AUTH_COOKIE_NAME}=jwt")
        )
        expect(status).to eq(200)
      end
    end
  end

  describe "requests without the auth cookie", csrf_enforced: true do
    it "passes through — Bearer callers aren't CSRF-exposed" do
      status, = middleware.call(
        env_for(method: "POST", cookie: "some_other_cookie=1")
      )
      expect(status).to eq(200)
    end

    it "passes through even with no cookies at all" do
      status, = middleware.call(env_for(method: "POST"))
      expect(status).to eq(200)
    end

    it "does not false-match a cookie whose name merely ends with the auth cookie name" do
      # E.g. embedAuthToken should not trigger the CSRF gate.
      status, = middleware.call(
        env_for(method: "POST", cookie: "embedAuthToken=xyz")
      )
      expect(status).to eq(200)
    end
  end

  describe "cookie-authenticated mutating requests", csrf_enforced: true do
    let(:csrf_value) { "abc123csrf" }
    let(:auth_cookie) { "#{AuthCookies::AUTH_COOKIE_NAME}=jwt" }
    let(:csrf_cookie) { "#{AuthCookies::CSRF_COOKIE_NAME}=#{csrf_value}" }

    it "passes through when the X-CSRF-Token header matches the csrf-token cookie" do
      status, = middleware.call(
        env_for(
          method: "POST",
          cookie: "#{auth_cookie}; #{csrf_cookie}",
          csrf_header: csrf_value
        )
      )
      expect(status).to eq(200)
    end

    it "returns 403 when the header is missing" do
      status, _, body = middleware.call(
        env_for(method: "POST", cookie: "#{auth_cookie}; #{csrf_cookie}")
      )
      expect(status).to eq(403)
      expect(body.first).to eq("CSRF token mismatch")
    end

    it "returns 403 when the csrf-token cookie is missing" do
      status, = middleware.call(
        env_for(method: "POST", cookie: auth_cookie, csrf_header: csrf_value)
      )
      expect(status).to eq(403)
    end

    it "returns 403 when header and cookie values differ" do
      status, = middleware.call(
        env_for(
          method: "POST",
          cookie: "#{auth_cookie}; #{csrf_cookie}",
          csrf_header: "wrong-value"
        )
      )
      expect(status).to eq(403)
    end

    it "returns 403 when both are empty strings" do
      status, = middleware.call(
        env_for(
          method: "POST",
          cookie: "#{auth_cookie}; #{AuthCookies::CSRF_COOKIE_NAME}=",
          csrf_header: ""
        )
      )
      expect(status).to eq(403)
    end

    %w[PUT PATCH DELETE].each do |method|
      it "enforces CSRF on #{method} the same as POST" do
        status, = middleware.call(
          env_for(method:, cookie: auth_cookie)
        )
        expect(status).to eq(403)
      end
    end
  end
end
