# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe OauthClientCredentials do
      # Minimal host class that includes the module — mirrors how a real
      # connector client uses it (holds a `@connector_instance` that responds
      # to `configuration` / `update!`).
      let(:host_class) do
        Class.new do
          include Multiwoven::Integrations::Core::OauthClientCredentials
          attr_accessor :connector_instance

          def initialize(instance)
            @connector_instance = instance
          end
        end
      end

      # In-memory stand-in for a persisted Connector AR record.
      let(:connector_instance) do
        Class.new do
          attr_accessor :configuration

          def initialize(config)
            @configuration = config
          end

          def update!(attrs)
            @configuration = attrs[:configuration]
            true
          end
        end
      end

      let(:token_url) { "https://login.example.com/oauth2/v2.0/token" }
      let(:base_config) do
        {
          auth_type: "oauth_client_credentials",
          token_url: token_url,
          client_id: "cid",
          client_secret: "csecret",
          scope: "https://graph.microsoft.com/.default"
        }.with_indifferent_access
      end

      def stub_token(access_token: "tok", expires_in: 3600, status: 200, body: nil)
        response_body = body || (status == 200 ? { access_token: access_token, expires_in: expires_in }.to_json : "denied")
        stub_request(:post, token_url).to_return(
          status: status,
          body: response_body,
          headers: { "Content-Type" => "application/json" }
        )
      end

      describe "#build_headers" do
        context "when auth_type is not oauth_client_credentials" do
          it "returns the original headers unchanged and does not call the token endpoint" do
            host = host_class.new(nil)
            config = { headers: { "X-Trace" => "abc" }, auth_type: "none" }.with_indifferent_access

            result = host.build_headers(config)

            expect(result).to eq("X-Trace" => "abc")
            expect(WebMock).not_to have_requested(:post, token_url)
          end

          it "returns an empty hash when no headers are provided" do
            host = host_class.new(nil)
            expect(host.build_headers({ auth_type: "none" }.with_indifferent_access)).to eq({})
          end

          it "returns a defensive copy of the caller's headers" do
            host = host_class.new(nil)
            original = { "X-Trace" => "abc" }
            result = host.build_headers({ headers: original, auth_type: "none" }.with_indifferent_access)
            result["mutated"] = "yes"
            expect(original).not_to have_key("mutated")
          end
        end

        context "when auth_type is oauth_client_credentials" do
          it "adds the Bearer token alongside existing headers" do
            host = host_class.new(nil)
            stub_token(access_token: "tok-1")

            result = host.build_headers(base_config.merge(headers: { "X-Trace" => "abc" }))

            expect(result["Authorization"]).to eq("Bearer tok-1")
            expect(result["X-Trace"]).to eq("abc")
          end
        end
      end

      describe "#ensure_oauth_token" do
        context "without a connector_instance to cache into" do
          it "fetches a fresh token on every call" do
            host = host_class.new(nil)
            stub_token(access_token: "tok-a")

            expect(host.ensure_oauth_token(base_config)).to eq("tok-a")
            expect(host.ensure_oauth_token(base_config)).to eq("tok-a")
            expect(WebMock).to have_requested(:post, token_url).twice
          end
        end

        context "with a connector_instance holding a fresh cached token" do
          it "returns the cached token and skips the token endpoint" do
            instance = connector_instance.new(
              "oauth_access_token" => "cached-tok",
              "oauth_expires_at" => (Time.now + 3600).iso8601
            )
            host = host_class.new(instance)

            expect(host.ensure_oauth_token(base_config)).to eq("cached-tok")
            expect(WebMock).not_to have_requested(:post, token_url)
          end
        end

        context "with a connector_instance holding a near-expiry token" do
          it "refreshes and persists the new token" do
            instance = connector_instance.new(
              "oauth_access_token" => "stale-tok",
              "oauth_expires_at" => (Time.now + 60).iso8601 # inside 300s buffer
            )
            host = host_class.new(instance)
            stub_token(access_token: "fresh-tok", expires_in: 7200)

            expect(host.ensure_oauth_token(base_config)).to eq("fresh-tok")
            expect(instance.configuration["oauth_access_token"]).to eq("fresh-tok")
            expect(Time.parse(instance.configuration["oauth_expires_at"])).to be > Time.now + 6000
          end
        end

        context "with a connector_instance that has no cached token yet" do
          it "fetches a token and writes it back" do
            instance = connector_instance.new({})
            host = host_class.new(instance)
            stub_token(access_token: "first-tok")

            expect(host.ensure_oauth_token(base_config)).to eq("first-tok")
            expect(instance.configuration["oauth_access_token"]).to eq("first-tok")
          end
        end

        context "with a corrupted expires_at value in the config" do
          it "treats the cache as invalid and re-fetches" do
            instance = connector_instance.new(
              "oauth_access_token" => "cached-tok",
              "oauth_expires_at" => "not-a-timestamp"
            )
            host = host_class.new(instance)
            stub_token(access_token: "recovered-tok")

            expect(host.ensure_oauth_token(base_config)).to eq("recovered-tok")
            expect(instance.configuration["oauth_access_token"]).to eq("recovered-tok")
          end
        end

        context "when required OAuth fields are missing" do
          it "raises ArgumentError when token_url is blank" do
            host = host_class.new(nil)
            config = base_config.merge(token_url: "")

            expect { host.ensure_oauth_token(config) }.to raise_error(ArgumentError, /token_url/)
            expect(WebMock).not_to have_requested(:post, token_url)
          end

          it "raises ArgumentError when client_id is blank" do
            host = host_class.new(nil)
            expect { host.ensure_oauth_token(base_config.merge(client_id: "")) }.to raise_error(ArgumentError)
          end

          it "raises ArgumentError when client_secret is blank" do
            host = host_class.new(nil)
            expect { host.ensure_oauth_token(base_config.merge(client_secret: "")) }.to raise_error(ArgumentError)
          end
        end

        context "when the token endpoint responds with an error" do
          it "raises with the status and body" do
            host = host_class.new(nil)
            stub_token(status: 401, body: "invalid_client")

            expect { host.ensure_oauth_token(base_config) }.to raise_error(/401.*invalid_client/)
          end
        end

        context "when the token response is malformed" do
          it "raises when access_token is missing" do
            host = host_class.new(nil)
            stub_token(body: { expires_in: 3600 }.to_json)

            expect { host.ensure_oauth_token(base_config) }.to raise_error(/access_token/)
          end
        end
      end

      describe "token request body" do
        it "sends grant_type, client_id, client_secret, and scope as form-urlencoded" do
          host = host_class.new(nil)
          stub_token(access_token: "tok-x")

          host.ensure_oauth_token(base_config)

          expect(WebMock).to(have_requested(:post, token_url).with do |req|
            req.headers["Content-Type"] == "application/x-www-form-urlencoded" &&
              URI.decode_www_form(req.body).to_h == {
                "grant_type" => "client_credentials",
                "client_id" => "cid",
                "client_secret" => "csecret",
                "scope" => "https://graph.microsoft.com/.default"
              }
          end)
        end

        it "omits scope from the form when it is blank" do
          host = host_class.new(nil)
          stub_token(access_token: "tok-x")

          host.ensure_oauth_token(base_config.merge(scope: ""))

          expect(WebMock).to(have_requested(:post, token_url).with do |req|
            !URI.decode_www_form(req.body).to_h.key?("scope")
          end)
        end

        it "defaults expires_in to 3600 seconds when the response omits it" do
          instance = connector_instance.new({})
          host = host_class.new(instance)
          stub_token(body: { access_token: "tok-x" }.to_json)

          host.ensure_oauth_token(base_config)

          persisted = Time.parse(instance.configuration["oauth_expires_at"])
          expect(persisted).to be_between(Time.now + 3500, Time.now + 3700)
        end
      end
    end
  end
end
