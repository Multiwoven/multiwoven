# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/middleware/multiwoven_server/embed_cors"

RSpec.describe MultiwovenServer::EmbedCors do
  let(:inner_response_headers) { {} }
  let(:inner_response) { [200, inner_response_headers, ["ok"]] }
  let(:inner_app) { ->(_env) { inner_response } }
  subject(:middleware) { described_class.new(inner_app) }

  let(:organization) { create(:organization) }
  let(:workspace)    { create(:workspace, organization:) }
  let!(:data_app)    { create(:data_app, workspace:) }
  let(:user)         { create(:user) }

  def env_for(path:, method: "GET", origin: nil, data_app_id: nil, request_headers: nil)
    env = Rack::MockRequest.env_for(path, method:)
    env["HTTP_ORIGIN"]                          = origin if origin
    env["HTTP_DATA_APP_ID"]                     = data_app_id if data_app_id
    env["HTTP_ACCESS_CONTROL_REQUEST_HEADERS"]  = request_headers if request_headers
    env
  end

  def restore_env(key, original)
    if original.nil?
      ENV.delete(key)
    else
      ENV[key] = original
    end
  end

  # Pin CORS_ALLOWED_ORIGINS so the global-match fallback in
  # EmbedOrigins::Registry.allowed? is deterministic. Without this, tests
  # inherit the temporary "*" default and every "evil.com should be blocked"
  # assertion would spuriously pass through the global wildcard.
  around do |example|
    original = ENV["CORS_ALLOWED_ORIGINS"]
    ENV["CORS_ALLOWED_ORIGINS"] = "https://squared.ai"
    example.run
  ensure
    restore_env("CORS_ALLOWED_ORIGINS", original)
  end

  before do
    create(:user_embed_origin,
           created_by_user: user, origin: "https://customer.com",
           organization:, workspace:)
    EmbedOrigins::Registry.refresh!
  end

  # Enforcement examples opt out of the default bypass (EMBED_CORS_BYPASS defaults to true).
  around(:each, embed_cors_enforced: true) do |example|
    original = ENV["EMBED_CORS_BYPASS"]
    ENV["EMBED_CORS_BYPASS"] = "false"
    example.run
  ensure
    restore_env("EMBED_CORS_BYPASS", original)
  end

  describe "EMBED_CORS_BYPASS flag" do
    around do |example|
      original = ENV["EMBED_CORS_BYPASS"]
      example.run
    ensure
      restore_env("EMBED_CORS_BYPASS", original)
    end

    it "passes through without stripping when EMBED_CORS_BYPASS=true" do
      ENV["EMBED_CORS_BYPASS"] = "true"
      inner_response_headers["access-control-allow-origin"] = "*"

      status, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )

      expect(status).to eq(200)
      expect(headers["access-control-allow-origin"]).to eq("*")
    end

    it "enforces by default when EMBED_CORS_BYPASS is unset" do
      ENV.delete("EMBED_CORS_BYPASS")
      inner_response_headers["access-control-allow-origin"] = "*"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )

      expect(headers).not_to have_key("access-control-allow-origin")
    end

    it "enforces allowlisting when EMBED_CORS_BYPASS=false", :embed_cors_enforced do
      inner_response_headers["access-control-allow-origin"] = "*"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )

      expect(headers).not_to have_key("access-control-allow-origin")
    end
  end

  describe "non-embed request (no tenant identifier)", :embed_cors_enforced do
    it "passes through without touching CORS headers" do
      status, headers, = middleware.call(env_for(path: "/enterprise/api/v1/syncs", origin: "https://customer.com"))
      expect(status).to eq(200)
      expect(headers).not_to have_key("access-control-allow-origin")
    end
  end

  describe "allowlisted origin", :embed_cors_enforced do
    it "echoes the request origin on the response" do
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://customer.com", data_app_id: data_app.id.to_s)
      )
      expect(headers["access-control-allow-origin"]).to eq("https://customer.com")
      expect(headers["access-control-allow-credentials"]).to eq("true")
      expect(headers["vary"]).to include("Origin")
    end

    it "echoes even when origin has a trailing slash" do
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://customer.com/", data_app_id: data_app.id.to_s)
      )
      expect(headers["access-control-allow-origin"]).to eq("https://customer.com/") # echo raw
      expect(headers["access-control-allow-credentials"]).to eq("true")
    end
  end

  describe "non-allowlisted origin", :embed_cors_enforced do
    it "strips any ACAO set by an inner middleware" do
      inner_response_headers["access-control-allow-origin"] = "https://evil.com"
      inner_response_headers["access-control-allow-credentials"] = "true"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )
      expect(headers).not_to have_key("access-control-allow-origin")
      expect(headers).not_to have_key("access-control-allow-credentials")
    end

    it "also strips mixed-case Rack::Cors headers (defense against Rack 2 shape)" do
      inner_response_headers["Access-Control-Allow-Origin"] = "https://evil.com"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )
      expect(headers).not_to have_key("Access-Control-Allow-Origin")
    end
  end

  describe "workspace resolution from URL when header is absent (preflight case)", :embed_cors_enforced do
    it "extracts data_app_id from /data_apps/:id/* and matches allowlist" do
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "OPTIONS", origin: "https://customer.com",
                request_headers: "data-app-id,data-app-token")
      )
      expect(headers["access-control-allow-origin"]).to eq("https://customer.com")
    end

    it "returns passthrough when the DataApp id is unknown" do
      status, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/999999/fetch_data",
                method: "OPTIONS", origin: "https://customer.com")
      )
      expect(status).to eq(200) # passthrough: inner app returned 200
      expect(headers).not_to have_key("access-control-allow-origin")
    end
  end

  describe "preflight (OPTIONS)", :embed_cors_enforced do
    it "returns 204 with tenant-specific ACAO when origin allowlisted" do
      status, headers, body = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "OPTIONS", origin: "https://customer.com", data_app_id: data_app.id.to_s,
                request_headers: "data-app-id,data-app-token")
      )
      expect(status).to eq(204)
      expect(body).to eq([])
      expect(headers["access-control-allow-origin"]).to eq("https://customer.com")
      expect(headers["access-control-allow-credentials"]).to eq("true")
      expect(headers["access-control-allow-methods"]).to include("POST")
      expect(headers["access-control-max-age"]).to eq("3600")
      expect(headers["vary"]).to include("Origin")
    end

    it "returns 204 WITHOUT ACAO when origin is not allowlisted" do
      status, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "OPTIONS", origin: "https://evil.com", data_app_id: data_app.id.to_s)
      )
      expect(status).to eq(204)
      expect(headers).not_to have_key("access-control-allow-origin")
    end
  end

  describe "public paths (runner script)", :embed_cors_enforced do
    it "returns ACAO: * on GET" do
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps_runner.js", origin: "https://anyone.com")
      )
      expect(headers["access-control-allow-origin"]).to eq("*")
      expect(headers).not_to have_key("access-control-allow-credentials")
    end

    it "returns 204 + ACAO: * on OPTIONS preflight" do
      status, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps_runner.js",
                method: "OPTIONS", origin: "https://anyone.com")
      )
      expect(status).to eq(204)
      expect(headers["access-control-allow-origin"]).to eq("*")
    end
  end

  describe "agentic-app resolution is removed", :embed_cors_enforced do
    # These previously flowed through EmbedOrigins::Registry.workspace_id_for_agentic_app.
    # After the removal, requests with HTTP_AGENTIC_APP_ID or a path under
    # /agentic_coding/apps/:id must be treated as non-embed traffic (no ACAO,
    # no stripping), even for the allowlisted "customer.com" origin.
    it "ignores HTTP_AGENTIC_APP_ID header and passes through untouched" do
      inner_response_headers["access-control-allow-origin"] = "*"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/agentic_coding/apps/00000000-0000-0000-0000-000000000000/action",
                method: "POST", origin: "https://customer.com").merge(
                  "HTTP_AGENTIC_APP_ID" => "00000000-0000-0000-0000-000000000000"
                )
      )
      # Passthrough: inner ACAO left untouched, no tenant-scoped ACAO applied.
      expect(headers["access-control-allow-origin"]).to eq("*")
    end

    it "ignores /agentic_coding/apps/:id path pattern (no workspace resolution)" do
      inner_response_headers["access-control-allow-origin"] = "*"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/agentic_coding/apps/00000000-0000-0000-0000-000000000000/action",
                method: "POST", origin: "https://customer.com")
      )
      expect(headers["access-control-allow-origin"]).to eq("*")
    end
  end

  describe "global CORS_ALLOWED_ORIGINS fallback", :embed_cors_enforced do
    # Overrides the outer around block so the global matcher list expands
    # *.squared.ai — an origin not in the workspace list but matching the
    # global list must still be echoed.
    around do |example|
      original = ENV["CORS_ALLOWED_ORIGINS"]
      ENV["CORS_ALLOWED_ORIGINS"] = "*.squared.ai"
      EmbedOrigins::Registry.refresh!
      example.run
    ensure
      restore_env("CORS_ALLOWED_ORIGINS", original)
      EmbedOrigins::Registry.refresh!
    end

    it "allows an origin matching a global wildcard even when not in the workspace allowlist" do
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://embed.squared.ai", data_app_id: data_app.id.to_s)
      )
      expect(headers["access-control-allow-origin"]).to eq("https://embed.squared.ai")
      expect(headers["access-control-allow-credentials"]).to eq("true")
    end

    it "still rejects look-alike origins that resemble but don't match the global wildcard" do
      inner_response_headers["access-control-allow-origin"] = "*"

      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://squared.ai.evil.com", data_app_id: data_app.id.to_s)
      )
      expect(headers).not_to have_key("access-control-allow-origin")
    end
  end

  describe "case-insensitive header collision (Rack 3)", :embed_cors_enforced do
    it "does not emit duplicate ACAO when inner middleware set the mixed-case version" do
      inner_response_headers["Access-Control-Allow-Origin"] = "https://customer.com" # simulate Rack::Cors mixed-case
      _, headers, = middleware.call(
        env_for(path: "/enterprise/api/v1/data_apps/#{data_app.id}/fetch_data",
                method: "POST", origin: "https://customer.com", data_app_id: data_app.id.to_s)
      )
      expect(headers.keys.count { |k| k.downcase == "access-control-allow-origin" }).to eq(1)
      expect(headers["access-control-allow-origin"]).to eq("https://customer.com")
    end
  end
end
