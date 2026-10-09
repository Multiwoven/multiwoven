# frozen_string_literal: true

require "rails_helper"

RSpec.describe MultiwovenServer::RequestResponseLogger do
  let(:app) { double("app") }
  let(:env) do
    Rack::MockRequest.env_for(
      "/api/v1/users",
      method: "POST",
      "CONTENT_TYPE" => "application/json",
      "HTTP_WORKSPACE_ID" => "1",
      input: '{"name": "John Doe"}'
    )
  end

  subject { described_class.new(app) }

  before do
    stub_const("ENV", ENV.to_hash.merge("APPSIGNAL_PUSH_API_KEY" => "some_api_key"))
  end

  describe "#call" do
    it "logs request details" do
      allow(app).to receive(:call).with(env).and_return([201, {}, double(body: "User created")])
      allow_any_instance_of(described_class).to receive(:log_response).and_return(nil)

      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:request_method]).to eq("POST")
        expect(log_data[:request_url]).to eq("http://example.org/api/v1/users")
        expect(log_data[:request_params]).to eq({ "name" => "John Doe" })
        expect(log_data[:request_headers].transform_keys(&:to_s)).to eq(
          {
            "Workspace-Id" => "1",
            "Origin" => nil,
            "Referer" => nil
          }
        )
      end.once

      subject.call(env)
    end

    it "logs Origin and Referer headers when present" do
      env_with_headers = Rack::MockRequest.env_for(
        "/api/v1/users",
        method: "POST",
        "CONTENT_TYPE" => "application/json",
        "HTTP_WORKSPACE_ID" => "1",
        "HTTP_ORIGIN" => "https://app.example.com",
        "HTTP_REFERER" => "https://app.example.com/data-apps/42/edit",
        input: '{"name": "John Doe"}'
      )
      allow(app).to receive(:call).with(env_with_headers)
                                  .and_return([201, {}, double(body: "User created")])
      allow_any_instance_of(described_class).to receive(:log_response).and_return(nil)

      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:request_headers].transform_keys(&:to_s)).to eq(
          {
            "Workspace-Id" => "1",
            "Origin" => "https://app.example.com",
            "Referer" => "https://app.example.com/data-apps/42/edit"
          }
        )
      end.once

      subject.call(env_with_headers)
    end

    it "logs nil for Origin and Referer when absent (same-origin case)" do
      env_no_origin = Rack::MockRequest.env_for(
        "/api/v1/users",
        method: "GET",
        "HTTP_WORKSPACE_ID" => "1"
      )
      allow(app).to receive(:call).with(env_no_origin).and_return([200, {}, double(body: "[]")])
      allow_any_instance_of(described_class).to receive(:log_response).and_return(nil)

      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        headers = log_data[:request_headers].transform_keys(&:to_s)
        expect(headers).to include("Origin" => nil, "Referer" => nil)
      end.once

      subject.call(env_no_origin)
    end

    it "logs response details" do
      allow(app).to receive(:call).with(env)
                                  .and_return([201, { "Content-Type" => "application/json" },
                                               double(body: "User created")])

      allow_any_instance_of(described_class).to receive(:log_request).and_return(nil)
      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:response_status]).to eq(201)
        expect(log_data[:response_body]).to eq("User created")
        expect(log_data[:response_headers]).to include("application/json")
      end.once

      subject.call(env)
    end

    it "logs response details with empty array" do
      allow(app).to receive(:call).with(env).and_return([201, { "Content-Type" => "application/json" }, []])

      allow_any_instance_of(described_class).to receive(:log_request).and_return(nil)
      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:response_status]).to eq(201)
        expect(log_data[:response_body]).to eq([])
        expect(log_data[:response_headers]).to include("application/json")
      end.once

      subject.call(env)
    end

    it "logs response details with empty nil" do
      allow(app).to receive(:call).with(env).and_return([201, { "Content-Type" => "application/json" }, nil])

      allow_any_instance_of(described_class).to receive(:log_request).and_return(nil)
      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:response_status]).to eq(201)
        expect(log_data[:response_body]).to eq([])
        expect(log_data[:response_headers]).to include("application/json")
      end.once

      subject.call(env)
    end
  end
end
