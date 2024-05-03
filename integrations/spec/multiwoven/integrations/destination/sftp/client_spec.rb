# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Sftp::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:mock_sftp_session) { double("Net::SFTP::Session") }
  let(:mock_sftp_file) { double("Net::SFTP::Operations::File") }
  let(:connection_config) do
    {
      host: "test_host",
      username: "test_username",
      port: 22,
      password: "test_password",
      destination_path: "/multiwoven",
      file_name: "test",
      format: {
        format_type: "csv",
        compression_type: "un_compressed"
      }
    }.with_indifferent_access
  end
  let(:sync_config_json) do
    { source: {
        name: "DestinationConnectorName",
        type: "destination",
        connection_specification: {
          private_api_key: "test_api_key"
        }
      },
      destination: {
        name: "Sftp",
        type: "destination",
        connection_specification: connection_config
      },
      model: {
        name: "ExampleModel",
        query: "SELECT * FROM CALL_CENTER LIMIT 1",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "sftp",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      { "id" => 1, "name" => "Test Record" }
    ]
  end
  let(:csv_content) { "id,name\n1,Test Record\n" }

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end

  def sync_config_compressed_zip
    sync_config_json[:destination][:connection_specification][:format][:compression_type] = "zip"
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
  describe "#check_connection" do
    it "successfully checks connection" do
      expect(client).to receive(:with_sftp_client).and_yield(double)
      expect(client).to receive(:test_file_operations)
      response = client.check_connection(connection_config)
      expect(response.connection_status.status).to eq("succeeded")
    end

    it "handles connection failure" do
      allow(client).to receive(:with_sftp_client).and_raise(StandardError.new("connection failed"))
      response = client.check_connection(connection_config)
      expect(response.connection_status.status).to eq("failed")
      expect(response.connection_status.message).to eq("connection failed")
    end
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(600)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      expect(catalog.streams.count).to eql(1)
      expect(catalog.schema_mode).to eql("schemaless")
      expect(catalog.streams[0].name).to eql("sftp")
      expect(catalog.streams[0].batch_support).to eql(true)
      expect(catalog.streams[0].batch_size).to eql(100_000)
      expect(catalog.streams[0].supported_sync_modes).to eql(%w[full_refresh incremental])
    end
  end

  describe "#write" do
    it "successfully writes records with un_compressed" do
      allow(client).to receive(:with_sftp_client).and_yield(mock_sftp_session)
      allow(client).to receive(:generate_csv_content).and_return(csv_content)
      allow(mock_sftp_session).to receive(:upload!).and_return(true)
      response = client.write(sync_config, records, "insert")
      expect(response.tracking.success).to eq(records.size)
      expect(response.tracking.failed).to eq(0)
    end

    it "successfully writes records with compressed" do
      allow(client).to receive(:with_sftp_client).and_yield(mock_sftp_session)
      allow(client).to receive(:generate_csv_content).and_return(csv_content)
      allow(mock_sftp_session).to receive(:upload!).and_return(true)
      response = client.write(sync_config_compressed_zip, records, "insert")
      expect(response.tracking.success).to eq(records.size)
      expect(response.tracking.failed).to eq(0)
    end

    it "handles the failure and increments the failure count" do
      allow(client).to receive(:with_sftp_client).and_yield(mock_sftp_session)
      allow(mock_sftp_session).to receive(:upload!).and_raise(StandardError, "SFTP upload failed")
      response = client.write(sync_config, records, "insert")

      # Account for handling failure outside the inner rescue block
      expect(response.tracking.failed).to eq(records.size)
      expect(response.tracking.success).to eq(0)
    end

    it "handles write failure with_sftp_client" do
      allow(client).to receive(:with_sftp_client).and_raise(StandardError.new("write failed"))
      response = client.write(sync_config, records, "insert")
      expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
      expect(response.log).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
      expect(response.log.level).to eq("error")
      expect(response.log.message).to eq("write failed")
      expect(response.log.name).to eq("SFTP:WRITE:EXCEPTION")
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven/main/integrations/lib/multiwoven/integrations/destination/sftp/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  describe "#clear_all_records" do
    let(:mock_sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
    let(:directory_entries_before) { [double("entry", name: "."), double("entry", name: ".."), double("entry", name: "file1.txt"), double("entry", name: "file2.txt")] }
    let(:directory_entries_after) { [double("entry", name: "."), double("entry", name: "..")] } # Simulating an empty directory after deletion
    let(:directory_entries_after_with_data) { [double("entry", name: "."), double("entry", name: ".."), double("entry", name: "test.csv")] } # Simulating an empty directory after deletion

    before do
      allow(client).to receive(:with_sftp_client).and_yield(mock_sftp_session)
      allow(mock_sftp_session).to receive(:dir).and_return(mock_sftp_dir)
      allow(mock_sftp_dir).to receive(:glob).and_return(directory_entries_before[2..]) # Simulate finding files to be deleted
      allow(mock_sftp_session).to receive(:remove!).and_return(true) # Simulate successful deletion
    end

    context "when files are successfully cleared" do
      it "returns a success control message" do
        allow(mock_sftp_dir).to receive(:entries).and_return(directory_entries_after)
        response = client.clear_all_records(sync_config)
        expect(response.control.status).to eq("succeeded")
        expect(response).to have_attributes(
          control: have_attributes(status: "succeeded", meta: { detail: "Successfully cleared data." })
        )
        expect(mock_sftp_session).to have_received(:remove!).twice
      end
    end

    context "when an error occurs while clearing files" do
      it "returns a failure control message" do
        allow(mock_sftp_session).to receive(:remove!).and_raise(StandardError.new("Failed to remove file"))

        response = client.clear_all_records(sync_config)
        expect(response).to have_attributes(
          control: have_attributes(status: "failed", meta: { detail: "Failed to remove file" })
        )
      end
    end

    context "clearing files is failed" do
      it "returns a failure control message" do
        allow(mock_sftp_dir).to receive(:entries).and_return(directory_entries_after_with_data)

        response = client.clear_all_records(sync_config)
        expect(response.control.status).to eq("failed")
        expect(response).to have_attributes(
          control: have_attributes(status: "failed", meta: { detail: "Failed to clear data." })
        )
      end
    end
  end

  describe "#generate_local_file_name" do
    it "generate file name for to upload sftp" do
      expect(client.send(:generate_local_file_name, sync_config)).to include("test_")
    end
  end

  describe "#generate_file_path" do
    it "generate csv file" do
      file_path = client.send(:generate_file_path, sync_config)
      expect(file_path).to match(%r{/multiwoven/test_\d{8}-\d{6}\.csv\z})
    end

    it "generate zip file" do
      file_path = client.send(:generate_file_path, sync_config_compressed_zip)
      expect(file_path).to match(%r{/multiwoven/test_\d{8}-\d{6}\.zip\z})
    end
  end
end
