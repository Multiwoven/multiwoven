# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rack::Attack, type: :request do
  # Rack::Attack safelists loopback; use a non-loopback IP so throttles fire.
  let(:non_local_ip) { "203.0.113.1" }
  let(:another_ip)   { "203.0.113.2" }
  let(:lookup_path)  { "/enterprise/api/v1/embed_origins/lookup" }

  before(:all) do
    NewRelic::Agent.shutdown if defined?(NewRelic::Agent)
    WebMock.disable_net_connect!(
      allow_localhost: true,
      allow: ["169.254.169.254", "metadata.google.internal", /\.newrelic\.com/]
    )
  end

  after(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  after do
    # Restore production limit so other specs in the same process are unaffected.
    Rack::Attack.throttles["embed_origins_lookup/ip"].instance_variable_set(:@limit, 120)
    Rack::Attack.cache.store = Rails.cache
    Rack::Attack.reset!
  end

  # Throttle limits are hardcoded integers evaluated once at boot, so stubbing
  # ENV has no effect — override on the throttle object directly.
  def lookup_limit(limit)
    Rack::Attack.throttles["embed_origins_lookup/ip"].instance_variable_set(:@limit, limit)
  end

  def get_lookup(ip: non_local_ip, data_app_id: 1, path: lookup_path)
    get path,
        params: { data_app_id: },
        headers: { "REMOTE_ADDR" => ip }
  end

  describe "embed_origins_lookup/ip throttle" do
    it "throttles after exceeding the per-IP limit" do
      lookup_limit(3)
      3.times { get_lookup }
      get_lookup
      expect(response).to have_http_status(429)
      expect(response.body).to include("Too many embed-origin lookups")
    end

    it "does not throttle requests under the limit" do
      lookup_limit(3)
      3.times { get_lookup }
      expect(response).not_to have_http_status(429)
    end

    it "counts across different data_app_ids from the same IP" do
      lookup_limit(3)
      3.times { |i| get_lookup(data_app_id: i + 1) }
      get_lookup(data_app_id: 99)
      expect(response).to have_http_status(429)
    end

    it "does not throttle a different IP" do
      lookup_limit(2)
      3.times { get_lookup(ip: non_local_ip) }
      get_lookup(ip: another_ip)
      expect(response).not_to have_http_status(429)
    end
  end

  describe "throttle scope" do
    it "does not throttle non-GET verbs on the same path" do
      lookup_limit(2)
      3.times { get_lookup } # saturate the GET counter
      post lookup_path,
           params: { data_app_id: 1 }.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "REMOTE_ADDR" => non_local_ip }
      expect(response).not_to have_http_status(429)
    end

    it "does not throttle other paths from the same IP" do
      lookup_limit(2)
      3.times { get_lookup }
      get "/up", headers: { "REMOTE_ADDR" => non_local_ip }
      expect(response).not_to have_http_status(429)
    end
  end
end
