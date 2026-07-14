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
        expect(log_data[:request_headers].transform_keys(&:to_s)).to eq({ "Workspace-Id" => "1" })
      end.once

      subject.call(env)
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
<<<<<<< HEAD
=======

    it "logs warning and empty params when multipart body is empty" do
      multipart_env = Rack::MockRequest.env_for(
        "/",
        method: "POST",
        "CONTENT_TYPE" => "multipart/form-data; boundary=----WebKitFormBoundary",
        "CONTENT_LENGTH" => "249",
        input: ""
      )
      allow(app).to receive(:call).with(multipart_env).and_return([400, {}, []])
      allow_any_instance_of(described_class).to receive(:log_response).and_return(nil)
      allow_any_instance_of(ActionDispatch::Request).to receive(:filtered_parameters)
        .and_raise(Rack::Multipart::EmptyContentError)

      expect(Rails.logger).to receive(:info).with("Malformed multipart body — skipping param logging").ordered
      expect(Rails.logger).to receive(:info) do |arg|
        log_data = eval(arg) # rubocop:disable Security/Eval
        expect(log_data[:request_params]).to eq({})
      end.ordered

      expect { subject.call(multipart_env) }.not_to raise_error
    end

    it "skips response body logging for SSE streams" do
      sse_response = double("sse_response", body: "should not be called")
      allow(app).to receive(:call).with(env)
                                  .and_return([200, { "Content-Type" => "text/event-stream" }, sse_response])

      allow_any_instance_of(described_class).to receive(:log_request).and_return(nil)
      expect(sse_response).not_to receive(:body)
      expect(Rails.logger).not_to receive(:info)

      subject.call(env)
    end

    it "skips response body logging for SSE streams with lowercase content-type" do
      sse_response = double("sse_response", body: "should not be called")
      allow(app).to receive(:call).with(env)
                                  .and_return([200, { "content-type" => "text/event-stream" }, sse_response])

      allow_any_instance_of(described_class).to receive(:log_request).and_return(nil)
      expect(sse_response).not_to receive(:body)
      expect(Rails.logger).not_to receive(:info)

      subject.call(env)
    end
>>>>>>> e6c2e16b7 (chore(CE): added a rescue for Rack::Multipart::EmptyContentError (#1928))
  end
end
