# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthCookies, type: :controller do
  # Anonymous controller to exercise the concern in a controller context —
  # `cookies`, `render`, and `request` are all available.
  controller(ApplicationController) do
    include AuthCookies
    skip_before_action :authenticate_user!
    skip_before_action :validate_contract
    skip_before_action :ensure_eula_accepted
    skip_after_action :verify_authorized

    def login
      write_auth_cookie("test-jwt-value")
      write_csrf_cookie
      render_auth_token("test-jwt-value", status: :ok)
    end

    def logout
      clear_all_auth_cookies
      head :no_content
    end
  end

  before do
    routes.draw do
      post "login" => "anonymous#login"
      delete "logout" => "anonymous#logout"
    end
  end

  def set_cookie_lines
    # Rack 2 uses a single string joined with "\n"; Rack 3 uses an Array.
    Array(response.headers["Set-Cookie"]).flat_map { |v| v.to_s.split("\n") }.reject(&:empty?)
  end

  describe "constants" do
    it "uses the plain 'authToken' name outside production" do
      # The spec suite runs with Rails.env=test, so the loaded constant should
      # not carry the __Host- prefix. Guards the "staging deploys as prod"
      # assumption from creeping into test env.
      expect(AuthCookies::AUTH_COOKIE_NAME).to eq("authTokenHttp")
    end

    it "exposes 'csrf-token' as the CSRF cookie name" do
      expect(AuthCookies::CSRF_COOKIE_NAME).to eq("csrf-token")
    end
  end

  describe "#write_auth_cookie" do
    it "sets an HttpOnly, SameSite=Lax cookie under AUTH_COOKIE_NAME" do
      post :login

      auth_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::AUTH_COOKIE_NAME}=") }
      expect(auth_line).not_to be_nil
      expect(auth_line).to match(/HttpOnly/i)
      expect(auth_line).to match(/SameSite=Lax/i)
      expect(auth_line).to match(%r{path=/}i)
    end

    it "does not mark the cookie Secure in the test environment" do
      post :login
      auth_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::AUTH_COOKIE_NAME}=") }
      expect(auth_line).not_to match(/Secure/i)
    end
  end

  describe "#write_csrf_cookie" do
    it "sets a non-HttpOnly csrf-token cookie with a hex value" do
      post :login

      csrf_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::CSRF_COOKIE_NAME}=") }
      expect(csrf_line).not_to be_nil
      expect(csrf_line).not_to match(/HttpOnly/i)
      # SecureRandom.hex(32) → 64 hex chars
      expect(csrf_line).to match(/#{AuthCookies::CSRF_COOKIE_NAME}=[0-9a-f]{64}/)
    end

    it "generates a fresh value each call" do
      post :login
      first = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::CSRF_COOKIE_NAME}=") }

      post :login
      second = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::CSRF_COOKIE_NAME}=") }

      expect(first).not_to eq(second)
    end
  end

  describe "#clear_all_auth_cookies" do
    # Rails only emits Set-Cookie for a delete when the cookie was already
    # present in the incoming request. Controller-spec cookie-jar plumbing
    # doesn't reliably wire that up. Instead, verify the concern calls
    # `cookies.delete` with the right names — that's the behaviour we own.
    it "calls cookies.delete for both auth and csrf cookies at path /" do
      # Get a handle on the actual jar the controller will use.
      jar = controller.send(:cookies)
      expect(jar).to receive(:delete).with(AuthCookies::AUTH_COOKIE_NAME, path: "/").ordered
      expect(jar).to receive(:delete).with(AuthCookies::CSRF_COOKIE_NAME, path: "/").ordered

      # Trigger the concern method directly on the controller instance so
      # the mocked jar is the one used.
      controller.send(:clear_all_auth_cookies)
    end
  end

  describe "#render_auth_token" do
    context "when json_jwt? is true (default)" do
      it "includes the JWT in the response body under data.attributes.token" do
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["type"]).to eq("token")
        expect(body["data"]["attributes"]["token"]).to eq("test-jwt-value")
      end

      it "returns a UUID as the id, not the JWT itself" do
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["id"]).to match(/\A[0-9a-f-]{36}\z/)
        expect(body["data"]["id"]).not_to eq("test-jwt-value")
      end
    end

    context "when BEARER_TOKEN_AUTH env var is set to 'false'" do
      around do |example|
        original = ENV["BEARER_TOKEN_AUTH"]
        ENV["BEARER_TOKEN_AUTH"] = "false"
        example.run
      ensure
        ENV["BEARER_TOKEN_AUTH"] = original
      end

      it "omits the token from the response body" do
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["attributes"]).to eq({})
      end

      it "still includes the token when the X-App-Context header is 'embed'" do
        request.headers["X-App-Context"] = "embed"
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["attributes"]["token"]).to eq("test-jwt-value")
      end
    end

    context "when BEARER_TOKEN_AUTH is any other value" do
      around do |example|
        original = ENV["BEARER_TOKEN_AUTH"]
        ENV["BEARER_TOKEN_AUTH"] = "yes"
        example.run
      ensure
        ENV["BEARER_TOKEN_AUTH"] = original
      end

      it "treats only exact 'true' (case-insensitive) as enabling, else omits token" do
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["attributes"]).to eq({})
      end
    end

    context "when BEARER_TOKEN_AUTH is unset" do
      around do |example|
        original = ENV["BEARER_TOKEN_AUTH"]
        ENV.delete("BEARER_TOKEN_AUTH")
        example.run
      ensure
        ENV["BEARER_TOKEN_AUTH"] = original
      end

      it "defaults to including the token (backwards compatible)" do
        post :login

        body = JSON.parse(response.body)
        expect(body["data"]["attributes"]["token"]).to eq("test-jwt-value")
      end
    end
  end
end
