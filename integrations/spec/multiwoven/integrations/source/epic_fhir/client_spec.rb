# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::EpicFhir::Client do
  include WebMock::API

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:token_url) { "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token" }
  let(:fhir_base_url) { "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4" }
  let(:status_url) { "#{fhir_base_url}/bulkstatus/job-1" }
  let(:file_url) { "#{fhir_base_url}/bulkfiles/patient-1.ndjson" }
  let(:connection_config) do
    {
      fhir_base_url: fhir_base_url,
      token_url: token_url,
      client_id: "epic-client",
      private_key: rsa_key.to_pem,
      kid: "test-kid",
      algorithm: "RS384",
      export_group_id: "g1",
      export_poll_interval: "0",
      config: { timeout: "30" }
    }.with_indifferent_access
  end
  let(:export_url) { "#{fhir_base_url}/Group/g1/$export" }
  let(:sync_config_json) do
    {
      source: {
        name: "EpicFhir",
        type: "source",
        connection_specification: connection_config
      },
      destination: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {}
      },
      model: {
        name: "Patients",
        query: "SELECT * FROM Patient",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "Patient",
        json_schema: {},
        request_method: "GET"
      },
      sync_mode: "full_refresh",
      destination_sync_mode: "upsert",
      sync_id: "1"
    }
  end
  let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }

  def stub_token(access_token: "tok-1")
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: access_token, expires_in: 3600 }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_fhir_get(url, body:, status: 200)
    stub_request(:get, url).to_return(
      status: status,
      body: body.is_a?(String) ? body : body.to_json,
      headers: { "Content-Type" => "application/fhir+json" }
    )
  end

  def stub_kickoff(url)
    stub_request(:get, url).to_return(
      status: 202,
      body: "",
      headers: { "Content-Location" => status_url }
    )
  end

  def stub_completed_export(resource_type: "Patient", resources: [])
    stub_request(:get, status_url).to_return(
      status: 200,
      body: { output: [{ type: resource_type, url: file_url }] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
    stub_request(:get, file_url).to_return(
      status: 200,
      body: resources.map(&:to_json).join("\n"),
      headers: { "Content-Type" => "application/fhir+ndjson" }
    )
  end

  describe "#check_connection" do
    it "validates OAuth without calling metadata" do
      stub_token

      expect(client.check_connection(connection_config).connection_status.status).to eq("succeeded")
      expect(WebMock).not_to have_requested(:get, "#{fhir_base_url}/metadata")
    end

    it "returns the token endpoint response when OAuth fails" do
      stub_request(:post, token_url).to_return(
        status: 403,
        body: { error: "invalid_client", error_description: "Client is not authorized" }.to_json
      )

      status = client.check_connection(connection_config).connection_status

      expect(status.status).to eq("failed")
      expect(status.message).to include("403", "invalid_client", "Client is not authorized")
      expect(WebMock).not_to have_requested(:get, "#{fhir_base_url}/metadata")
    end
  end

  describe "#discover" do
    it "builds streams from DEFAULT_RESOURCES without calling metadata or starting an export" do
      message = client.discover(connection_config)

      expect(message.catalog.streams.map(&:name)).to eq(
        Multiwoven::Integrations::Source::EpicFhir::DEFAULT_RESOURCES
      )
      expect(message.catalog.streams.first.source_defined_primary_key).to eq([["id"]])
      expect(message.catalog.streams.first.supported_sync_modes).to eq(%w[full_refresh])
      schema = message.catalog.streams.first.json_schema
      expect(schema["properties"].keys).to include("id", "resourceType", "meta", "extension")
      expect(schema["additionalProperties"]).to be(true)
      expect(message.catalog.streams.map { |stream| stream.json_schema["properties"].keys })
        .to all(eq(schema["properties"].keys))
      expect(WebMock).not_to have_requested(:get, "#{fhir_base_url}/metadata")
      expect(WebMock).not_to have_requested(:get, %r{/\$export})
    end

    it "uses configured export resource types" do
      config = connection_config.merge(resources: "Patient,Condition")

      message = client.discover(config)

      expect(message.catalog.streams.map(&:name)).to eq(%w[Patient Condition])
      expect(WebMock).not_to have_requested(:get, "#{fhir_base_url}/metadata")
    end
  end

  describe "#read" do
    it "exports from the configured group, never the system-level endpoint Epic does not serve" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_completed_export(resources: [{ resourceType: "Patient", id: "p1", active: true }])

      records = client.read(sync_config)

      expect(records.map { |record| record.record.data["id"] }).to eq(%w[p1])
      expect(WebMock).to(have_requested(:get, "#{export_url}?_type=Patient").with do |request|
        request.headers["Prefer"] == "respond-async"
      end)
      expect(WebMock).not_to have_requested(:get, "#{fhir_base_url}/$export?_type=Patient")
    end

    it "reports the missing group id instead of requesting an endpoint that always 404s" do
      config = connection_config.merge(export_group_id: "")

      expect do
        client.send(:query, config, "SELECT * FROM Patient")
      end.to raise_error(ArgumentError, /export_group_id/)
    end

    it "adds _since to the export request" do
      stub_token
      config = connection_config.merge(export_since: "2026-01-01T00:00:00Z")
      stub_kickoff("#{export_url}?_type=Patient&_since=2026-01-01T00%3A00%3A00Z")
      stub_completed_export

      client.send(:query, config, "SELECT * FROM Patient")

      expect(WebMock).to have_requested(
        :get,
        "#{export_url}?_type=Patient&_since=2026-01-01T00%3A00%3A00Z"
      )
    end

    it "makes nested FHIR objects and arrays displayable as JSON columns" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_completed_export(
        resources: [
          {
            resourceType: "Patient",
            id: "p1",
            active: true,
            name: [{ use: "official", family: "Davis", given: %w[Elijah John] }],
            managingOrganization: { reference: "Organization/o1", display: "Epic Hospital System" }
          }
        ]
      )

      data = client.send(:query, connection_config, "SELECT * FROM Patient").first.record.data

      expect(data["active"]).to be(true)
      expect(JSON.parse(data["name"])).to eq(
        [{ "use" => "official", "family" => "Davis", "given" => %w[Elijah John] }]
      )
      expect(JSON.parse(data["managingOrganization"])).to eq(
        "reference" => "Organization/o1",
        "display" => "Epic Hospital System"
      )
    end

    it "applies LIMIT and OFFSET to exported resources" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_completed_export(
        resources: %w[p1 p2 p3].map { |id| { resourceType: "Patient", id: id } }
      )

      records = client.send(:query, connection_config, "SELECT * FROM Patient LIMIT 1 OFFSET 1")

      expect(records.map { |record| record.record.data["id"] }).to eq(%w[p2])
    end

    it "returns no resources for LIMIT 0 without downloading export files" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_completed_export(
        resources: [{ resourceType: "Patient", id: "p1" }]
      )

      records = client.send(:query, connection_config, "SELECT * FROM Patient LIMIT 0")

      expect(records).to eq([])
      expect(WebMock).not_to have_requested(:get, file_url)
    end

    it "treats LIMIT 0 as reached before any records are collected" do
      expect(client.send(:limit_reached?, [], 0)).to be(true)
      expect(client.send(:limit_reached?, [], nil)).to be(false)
      expect(client.send(:limit_reached?, [{ "id" => "1" }], 1)).to be(true)
    end

    it "sends NDJSON Accept and bearer authorization headers" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_completed_export

      client.send(:query, connection_config, "SELECT * FROM Patient")

      expect(WebMock).to(have_requested(:get, file_url).with do |request|
        request.headers["Accept"] == "application/fhir+ndjson" &&
          request.headers["Authorization"] == "Bearer tok-1"
      end)
    end

    it "returns the export server response without custom hints" do
      stub_token
      body = { resourceType: "OperationOutcome", issue: [{ diagnostics: "Export unavailable" }] }.to_json
      stub_request(:get, "#{export_url}?_type=Patient").to_return(status: 403, body: body)

      expect do
        client.send(:query, connection_config, "SELECT * FROM Patient")
      end.to raise_error(StandardError, /403.*Export unavailable/)
    end

    it "times out when an export remains in progress" do
      stub_token
      stub_kickoff("#{export_url}?_type=Patient")
      stub_request(:get, status_url).to_return(status: 202, body: "")
      allow(client).to receive(:export_timeout).and_return(0)

      expect do
        client.send(:query, connection_config, "SELECT * FROM Patient")
      end.to raise_error(StandardError, /still in progress after 0/)
    end

    it "rejects a non-positive export_timeout" do
      expect do
        client.send(:query, connection_config.merge(export_timeout: "0"), "SELECT * FROM Patient")
      end.to raise_error(ArgumentError, /Export timeout must be greater than 0/)
    end

    it "rejects an export_timeout above the configured maximum" do
      expect do
        client.send(
          :query,
          connection_config.merge(export_timeout: (Multiwoven::Integrations::Source::EpicFhir::DEFAULT_EXPORT_TIMEOUT + 1).to_s),
          "SELECT * FROM Patient"
        )
      end.to raise_error(ArgumentError, /equal to or less than/)
    end
  end
end
