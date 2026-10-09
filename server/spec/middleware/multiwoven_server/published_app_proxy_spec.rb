# frozen_string_literal: true

require "rails_helper"

RSpec.describe MultiwovenServer::PublishedAppProxy do
  let(:downstream) { ->(_env) { [200, { "content-type" => "application/json" }, ["platform"]] } }
  let(:middleware) { described_class.new(downstream) }
  let(:domain) { "appbuilder-qa.squared.ai" }

  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:app_record) { create(:agentic_coding_app, workspace:, user:) }
  let(:session_record) { create(:agentic_coding_session, agentic_coding_app: app_record, workspace:) }

  before do
    stub_const("ENV", ENV.to_h.merge("APPGEN_PUBLISHED_DOMAIN" => domain))
  end

  def call_middleware(path = "/", host: "#{app_record.id}.#{domain}", method: "GET", input: "", env_extra: {})
    env = Rack::MockRequest.env_for("https://#{host}#{path}", method:, input:)
    env.merge!(env_extra)
    middleware.call(env)
  end

  def drain(body)
    chunks = []
    body.each { |chunk| chunks << chunk }
    body.close if body.respond_to?(:close)
    chunks.join
  end

  describe "pass-through" do
    it "passes through when APPGEN_PUBLISHED_DOMAIN is not set" do
      stub_const("ENV", ENV.to_h.merge("APPGEN_PUBLISHED_DOMAIN" => ""))
      status, _headers, body = call_middleware("/", host: "anything.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "passes through hosts outside the published domain" do
      status, _headers, body = call_middleware("/sessions", host: "api.qa.squared.ai")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "passes through the bare published domain (no subdomain)" do
      status, _headers, body = call_middleware("/", host: domain)
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end
  end

  describe "fall-through when no published app matches" do
    it "falls through for an unknown slug" do
      status, _headers, body = call_middleware("/", host: "notauuid.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through for an unknown app id" do
      status, _headers, body = call_middleware("/", host: "#{SecureRandom.uuid}.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through for invalid DNS labels" do
      status, _headers, body = call_middleware("/", host: "bad_slug.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through when the app has no succeeded deployment" do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :failed, deploy_url: "https://failed.modal.host")
      status, _headers, body = call_middleware("/")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through when the succeeded deployment has a blank deploy_url" do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :succeeded, deploy_url: "")
      status, _headers, body = call_middleware("/")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through for platform API subdomains matching the wildcard" do
      stub_const("ENV", ENV.to_h.merge("APPGEN_PUBLISHED_DOMAIN" => "qa.squared.ai"))
      fresh = described_class.new(downstream)
      env = Rack::MockRequest.env_for("https://api.qa.squared.ai/api/v1/login", method: "POST")
      status, _headers, body = fresh.call(env)
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end
  end

  describe "proxying" do
    let!(:deployment) do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :succeeded, deploy_url: "https://ta-test.modal.host",
                                         deployed_at: Time.current)
    end

    it "proxies GET with path and query, rewriting the Host header" do
      stub = stub_request(:get, "https://ta-test.modal.host/dashboard?tab=1")
             .with(headers: { "Host" => "ta-test.modal.host",
                              "X-Forwarded-Host" => "#{app_record.id}.#{domain}" })
             .to_return(status: 200, body: "hello", headers: { "Content-Type" => "text/html" })

      status, headers, body = call_middleware("/dashboard?tab=1")

      expect(status).to eq(200)
      expect(headers["content-type"]).to eq("text/html")
      expect(drain(body)).to eq("hello")
      expect(stub).to have_been_requested
    end

    it "proxies to the most recent succeeded deployment" do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :succeeded,
                                         deploy_url: "https://ta-old.modal.host", deployed_at: 1.day.ago)
      stub = stub_request(:get, "https://ta-test.modal.host/").to_return(status: 200, body: "newest")

      _status, _headers, body = call_middleware("/")

      expect(drain(body)).to eq("newest")
      expect(stub).to have_been_requested
    end

    it "forwards POST bodies and content type" do
      stub = stub_request(:post, "https://ta-test.modal.host/api/chat")
             .with(body: '{"msg":"hi"}', headers: { "Content-Type" => "application/json" })
             .to_return(status: 201, body: "ok")

      status, _headers, body = call_middleware("/api/chat", method: "POST", input: '{"msg":"hi"}',
                                                            env_extra: { "CONTENT_TYPE" => "application/json" })

      expect(status).to eq(201)
      expect(drain(body)).to eq("ok")
      expect(stub).to have_been_requested
    end

    it "passes response status codes and cookies through" do
      stub_request(:get, "https://ta-test.modal.host/login")
        .to_return(status: 302, body: "", headers: { "Location" => "/home", "Set-Cookie" => "sid=abc; HttpOnly" })

      status, headers, body = call_middleware("/login")
      drain(body)

      expect(status).to eq(302)
      expect(headers["location"]).to eq("/home")
      expect(headers["set-cookie"]).to eq("sid=abc; HttpOnly")
    end

    it "preserves multiple Set-Cookie headers as an array" do
      stub_request(:get, "https://ta-test.modal.host/")
        .to_return(status: 200, body: "x", headers: { "Set-Cookie" => ["a=1; Path=/", "b=2; Path=/"] })

      _status, headers, body = call_middleware("/")
      drain(body)

      expect(Array(headers["set-cookie"])).to contain_exactly("a=1; Path=/", "b=2; Path=/")
    end

    %w[PUT PATCH DELETE].each do |verb|
      it "proxies #{verb} requests" do
        stub = stub_request(verb.downcase.to_sym, "https://ta-test.modal.host/api/item/1")
               .to_return(status: 204, body: "")

        status, _headers, body = call_middleware("/api/item/1", method: verb)
        drain(body)

        expect(status).to eq(204)
        expect(stub).to have_been_requested
      end
    end

    it "forwards the client IP chain as X-Forwarded-For" do
      stub = stub_request(:get, "https://ta-test.modal.host/")
             .with(headers: { "X-Forwarded-For" => "203.0.113.7", "X-Forwarded-Proto" => "https" })
             .to_return(status: 200, body: "ok")

      _status, _headers, body = call_middleware("/", env_extra: { "REMOTE_ADDR" => "203.0.113.7" })
      drain(body)

      expect(stub).to have_been_requested
    end

    it "streams a large request body upstream (Content-Length path)" do
      payload = "x" * 50_000
      stub = stub_request(:post, "https://ta-test.modal.host/upload")
             .with(body: payload).to_return(status: 201, body: "stored")

      status, _headers, body = call_middleware("/upload", method: "POST", input: payload,
                                                          env_extra: { "CONTENT_TYPE" => "application/octet-stream" })

      expect(status).to eq(201)
      expect(drain(body)).to eq("stored")
      expect(stub).to have_been_requested
    end

    it "returns a streaming body that enumerates upstream chunks" do
      stub_request(:get, "https://ta-test.modal.host/events").to_return(status: 200, body: "chunked-output")

      _status, _headers, body = call_middleware("/events")

      expect(body).to be_a(MultiwovenServer::PublishedAppProxy::StreamingBody)
      collected = +""
      body.each { |chunk| collected << chunk }
      body.close
      expect(collected).to eq("chunked-output")
    end

    it "forwards query strings with an empty path as root" do
      stub = stub_request(:get, "https://ta-test.modal.host/?q=1").to_return(status: 200, body: "q")

      env = Rack::MockRequest.env_for("https://#{app_record.id}.#{domain}?q=1")
      status, _headers, body = middleware.call(env)
      drain(body)

      expect(status).to eq(200)
      expect(stub).to have_been_requested
    end

    it "rewrites absolute redirects pointing at the Modal host back to the public host" do
      stub_request(:get, "https://ta-test.modal.host/oauth/callback")
        .to_return(status: 302, body: "",
                   headers: { "Location" => "https://ta-test.modal.host/dashboard?ok=1" })

      _status, headers, body = call_middleware("/oauth/callback")
      drain(body)

      expect(headers["location"]).to eq("https://#{app_record.id}.#{domain}/dashboard?ok=1")
    end

    it "leaves redirects to external hosts untouched" do
      stub_request(:get, "https://ta-test.modal.host/pay")
        .to_return(status: 302, body: "", headers: { "Location" => "https://stripe.com/checkout" })

      _status, headers, body = call_middleware("/pay")
      drain(body)

      expect(headers["location"]).to eq("https://stripe.com/checkout")
    end

    it "strips hop-by-hop response headers" do
      stub_request(:get, "https://ta-test.modal.host/")
        .to_return(status: 200, body: "x", headers: { "Connection" => "keep-alive", "X-Custom" => "1" })

      _status, headers, body = call_middleware("/")
      drain(body)

      expect(headers).not_to have_key("connection")
      expect(headers["x-custom"]).to eq("1")
    end

    it "returns 502 when the upstream is unreachable" do
      stub_request(:get, "https://ta-test.modal.host/").to_raise(Errno::ECONNREFUSED)

      status, _headers, body = call_middleware("/")

      expect(status).to eq(502)
      expect(drain(body)).to eq("Upstream unavailable")
    end

    it "returns 501 for WebSocket upgrade requests" do
      status, _headers, body = call_middleware("/", env_extra: { "HTTP_UPGRADE" => "websocket" })

      expect(status).to eq(501)
      expect(drain(body)).to eq("WebSocket connections are not supported")
    end
  end

  describe "slug subdomains" do
    let!(:deployment) do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :succeeded, deploy_url: "https://ta-test.modal.host",
                                         deployed_at: Time.current)
    end

    before { app_record.update!(slug: "my-cool-store") }

    it "resolves the app by slug" do
      stub = stub_request(:get, "https://ta-test.modal.host/dashboard").to_return(status: 200, body: "via-slug")

      status, _headers, body = call_middleware("/dashboard", host: "my-cool-store.#{domain}")

      expect(status).to eq(200)
      expect(drain(body)).to eq("via-slug")
      expect(stub).to have_been_requested
    end

    it "still resolves the same app by UUID (old links keep working)" do
      stub_request(:get, "https://ta-test.modal.host/").to_return(status: 200, body: "via-uuid")

      status, _headers, body = call_middleware("/", host: "#{app_record.id}.#{domain}")

      expect(status).to eq(200)
      expect(drain(body)).to eq("via-uuid")
    end

    it "falls through for an unknown slug" do
      status, _headers, body = call_middleware("/", host: "no-such-app.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end

    it "falls through for labels that are not valid DNS labels" do
      status, _headers, body = call_middleware("/", host: "bad_slug.#{domain}")
      expect(status).to eq(200)
      expect(drain(body)).to eq("platform")
    end
  end

  describe "frame-ancestors CSP" do
    let!(:deployment) do
      create(:agentic_coding_deployment, agentic_coding_session: session_record, agentic_coding_app: app_record,
                                         workspace:, status: :succeeded, deploy_url: "https://ta-test.modal.host",
                                         deployed_at: Time.current)
    end

    before do
      stub_request(:any, "https://ta-test.modal.host/")
        .to_return(status: 200, body: "ok", headers: { "Content-Type" => "text/html" })
    end

    it "injects frame-ancestors 'self' when the workspace has no allowed origins" do
      EmbedOrigins::Registry.refresh!
      _status, headers, body = call_middleware("/")
      drain(body) # flush the streaming body

      expect(headers["content-security-policy"]).to eq("frame-ancestors 'self'")
    end

    it "appends the workspace's allowed origins to frame-ancestors" do
      create(:user_embed_origin, organization: workspace.organization, workspace:,
                                 created_by_user: user, origin: "https://customer.com")
      EmbedOrigins::Registry.refresh!
      _status, headers, body = call_middleware("/")
      drain(body)

      expect(headers["content-security-policy"]).to eq("frame-ancestors 'self' https://customer.com")
    end

    it "preserves an upstream Content-Security-Policy by appending as a separate value" do
      stub_request(:get, "https://ta-test.modal.host/")
        .to_return(status: 200, body: "ok",
                   headers: { "Content-Security-Policy" => "default-src 'self'" })
      EmbedOrigins::Registry.refresh!
      _status, headers, body = call_middleware("/")
      drain(body)

      values = Array(headers["content-security-policy"])
      expect(values).to include("default-src 'self'")
      expect(values).to include("frame-ancestors 'self'")
    end
  end
end
