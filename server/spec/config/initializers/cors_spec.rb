# frozen_string_literal: true

require "rails_helper"

RSpec.describe CorsOriginParser do
  describe ".parse" do
    def matches?(parsed, origin)
      parsed.any? { |entry| entry.is_a?(Regexp) ? entry.match?(origin) : entry == origin }
    end

    it "returns an empty list when the input is blank" do
      expect(described_class.parse(nil)).to be_empty
      expect(described_class.parse("")).to be_empty
      expect(described_class.parse(" , ")).to be_empty
    end

    describe "the DEFAULT constant" do
      subject(:parsed) { described_class.parse(described_class::DEFAULT) }

      it "parses to a non-empty matcher list" do
        expect(parsed).not_to be_empty
      end

      it "is not the fully-permissive bare '*'" do
        expect(parsed).not_to include("*")
      end

      # Iterate DEFAULT itself so this survives changes to the constant.
      # Each entry is expanded into at least one representative test origin and
      # asserted against the parsed matcher list.
      described_class::DEFAULT.to_s.split(",").map(&:strip).reject(&:empty?).each do |entry|
        it "matches a representative origin for '#{entry}'" do
          origin =
            case entry
            when "localhost" then "http://localhost:3000"
            when /\A\*\.(?<domain>[a-z0-9.-]+)\z/i then "https://app.#{Regexp.last_match(:domain)}"
            else entry
            end
          expect(matches?(parsed, origin)).to be(true),
                                              "expected default to match #{origin} (source entry: #{entry.inspect})"
        end
      end
    end

    it "passes the bare '*' wildcard through unchanged so rack-cors treats it as any-origin" do
      expect(described_class.parse("*")).to eq(["*"])
    end

    it "preserves '*' when mixed with other entries" do
      parsed = described_class.parse("*, https://app.squared.ai , localhost")
      expect(parsed).to include("*", "https://app.squared.ai")
    end

    it "passes full origins through unchanged" do
      parsed = described_class.parse("https://app.squared.ai,https://staging.squared.ai")
      expect(parsed).to include("https://app.squared.ai", "https://staging.squared.ai")
    end

    it "expands localhost into loopback patterns on any port" do
      parsed = described_class.parse("localhost")
      expect(matches?(parsed, "http://localhost")).to be(true)
      expect(matches?(parsed, "http://localhost:3000")).to be(true)
      expect(matches?(parsed, "https://localhost:8000")).to be(true)
      expect(matches?(parsed, "http://127.0.0.1:5173")).to be(true)
    end

    it "does not let localhost match attacker-controlled hosts" do
      parsed = described_class.parse("localhost")
      expect(matches?(parsed, "http://localhost.evil.com")).to be(false)
      expect(matches?(parsed, "http://evil.com/localhost")).to be(false)
    end

    it "expands wildcard subdomains" do
      parsed = described_class.parse("*.squared.ai")
      expect(matches?(parsed, "https://app.squared.ai")).to be(true)
      expect(matches?(parsed, "https://app.staging.squared.ai")).to be(true)
      expect(matches?(parsed, "http://internal.squared.ai")).to be(true)
    end

    it "does not match the bare domain or look-alike domains for wildcards" do
      parsed = described_class.parse("*.squared.ai")
      expect(matches?(parsed, "https://squared.ai")).to be(false)
      expect(matches?(parsed, "https://evilsquared.ai")).to be(false)
      expect(matches?(parsed, "https://app.squared.ai.evil.com")).to be(false)
      expect(matches?(parsed, "https://squared.ai.evil.com")).to be(false)
    end

    it "handles mixed entries with whitespace" do
      parsed = described_class.parse(" https://app.squared.ai , *.squared.ai , localhost ")
      expect(matches?(parsed, "https://app.squared.ai")).to be(true)
      expect(matches?(parsed, "https://tenant.squared.ai")).to be(true)
      expect(matches?(parsed, "http://localhost:3000")).to be(true)
      expect(matches?(parsed, "https://evil.com")).to be(false)
    end
  end

  describe ".frame_ancestor_sources" do
    around do |example|
      original = ENV["CORS_ALLOWED_ORIGINS"]
      example.run
    ensure
      if original.nil?
        ENV.delete("CORS_ALLOWED_ORIGINS")
      else
        ENV["CORS_ALLOWED_ORIGINS"] = original
      end
    end

    def with_cors(value)
      ENV["CORS_ALLOWED_ORIGINS"] = value
      described_class.frame_ancestor_sources
    end

    it "returns full origins verbatim" do
      sources = with_cors("https://app.squared.ai,https://staging.squared.ai")
      expect(sources).to contain_exactly("https://app.squared.ai", "https://staging.squared.ai")
    end

    it "expands a wildcard subdomain into https + http CSP host-sources" do
      expect(with_cors("*.squared.ai")).to contain_exactly("https://*.squared.ai", "http://*.squared.ai")
    end

    it "expands 'localhost' into port-any loopback sources for CSP" do
      expect(with_cors("localhost")).to contain_exactly(
        "http://localhost:*", "https://localhost:*", "http://127.0.0.1:*"
      )
    end

    it "passes the bare '*' through so callers get fully-permissive framing" do
      expect(with_cors("*")).to eq(["*"])
    end

    it "handles mixed entries with whitespace" do
      sources = with_cors(" https://app.squared.ai , *.squared.ai , localhost ")
      expect(sources).to include(
        "https://app.squared.ai",
        "https://*.squared.ai",
        "http://localhost:*"
      )
    end

    it "returns an empty list when CORS_ALLOWED_ORIGINS is blank" do
      expect(with_cors("")).to be_empty
      expect(with_cors(" , ")).to be_empty
    end

    it "falls back to DEFAULT when CORS_ALLOWED_ORIGINS is unset" do
      ENV.delete("CORS_ALLOWED_ORIGINS")
      expect(described_class.frame_ancestor_sources).not_to be_empty
    end
  end

  describe ".configured_matchers" do
    around do |example|
      original = ENV["CORS_ALLOWED_ORIGINS"]
      example.run
    ensure
      if original.nil?
        ENV.delete("CORS_ALLOWED_ORIGINS")
      else
        ENV["CORS_ALLOWED_ORIGINS"] = original
      end
    end

    it "reads and parses CORS_ALLOWED_ORIGINS when set" do
      ENV["CORS_ALLOWED_ORIGINS"] = "https://app.squared.ai,*.tenants.internal"
      matchers = described_class.configured_matchers
      expect(matchers).to include("https://app.squared.ai")
      expect(matchers.any? { |m| m.is_a?(Regexp) }).to be(true)
    end

    it "falls back to DEFAULT when CORS_ALLOWED_ORIGINS is unset" do
      ENV.delete("CORS_ALLOWED_ORIGINS")
      expect(described_class.configured_matchers).to eq(described_class.parse(described_class::DEFAULT))
    end
  end

  # Removed alongside cookie_domain when auth cookies became host-only
  # (same-origin proxying via ui/server.js + ui/vite.config.ts handles
  # cross-host sharing between FE and API). Only CORS_ALLOWED_ORIGINS is
  # still consumed by the Rack::Cors block below the module.
  it "does not expose auth-cookie-domain helpers" do
    expect(described_class).not_to respond_to(:auth_allowed_origins)
    expect(described_class).not_to respond_to(:cookie_domain)
    expect(described_class.const_defined?(:AUTH_ALLOWED_ORIGINS_DEFAULT)).to be(false)
  end
end

RSpec.describe "Rack::Cors configuration", type: :request do
  before do
    stub_request(:put, "http://169.254.169.254/latest/api/token").to_return(status: 404)
    stub_request(:get, %r{\Ahttp://169\.254\.169\.254/}).to_return(status: 404)
    stub_request(:get, %r{\Ahttp://metadata\.google\.internal/}).to_return(status: 404)
  end

  it "does not return Access-Control-Allow-Credentials on a preflight" do
    process(:options, "/up",
            headers: {
              "HTTP_ORIGIN" => "https://staging.squared.ai",
              "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "POST"
            })

    expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil
  end
end
