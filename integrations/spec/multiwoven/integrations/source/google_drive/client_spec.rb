# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::GoogleDrive::Client do
  let(:client) { described_class.new }
  let(:fields) { "files(id, name, parents, mimeType), nextPageToken" }
  # let(:error_instance) { StandardError.new("Google Drive source error") }
  let(:credentials) do
    {
      type: "service_account",
      project_id: "multiwoven",
      private_key_id: "private_key_id",
      private_key: "private_key",
      client_email: "multiwoven@multiwoven.iam.gserviceaccount.com",
      client_id: "client_id",
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: "client_x509_cert_url",
      universe_domain: "googleapis.com"
    }
  end

  let(:sync_config) do
    {
      source: {
        name: "GoogleDrive",
        type: "source",
        connection_specification: {
          data_type: "structured",
          credentials_json: credentials,
          folder_name: "test_folder"
        }
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {
          private_api_key: "your_key"
        }
      },
      model: {
        name: "account",
        query: "SELECT * FROM invoices LIMIT 50",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "invoices",
        request_method: "POST",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: {}
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      sync_id: "1",
      sync_run_id: nil
    }
  end

  let(:semistructured_config) do
    {
      data_type: "semistructured",
      credentials_json: credentials,
      folder_name: "test_folder"
    }
  end

  let(:unstructured_config) do
    {
      data_type: "unstructured",
      credentials_json: credentials,
      folder_name: "test_folder"
    }
  end

  let(:catalog) do
    {
      "exception" => { "type" => "string" },
      "file_name" => { "type" => "string" },
      "id" => { "type" => "string" },
      "invoice_date" => { "type" => "string" },
      "invoice_number" => { "type" => "string" },
      "invoice_total" => { "type" => "string" },
      "line_items" => { "items" => { "properties" => { "item_description" => { "type" => "string" }, "item_number" => { "type" => "string" }, "item_price" => { "type" => "string" }, "item_quantity" => { "type" => "string" }, "line_total" => { "type" => "string" } }, "type" => "object" },
                        "type" => "array" },
      "purchase_order" => { "type" => "string" },
      "vendor_name" => { "type" => "string" },
      "results" => { "type" => "object" }
    }
  end

  let(:google_drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
  let(:expense_file) { Google::Apis::DriveV3::File.new(id: "1", name: "expense_file.pdf") }
  let(:specified_folder) { Google::Apis::DriveV3::File.new(id: "2", name: "folder") }
  let(:file_list) { Google::Apis::DriveV3::FileList.new(files: [expense_file]) }

  before do
    # allow(client).to receive(:create_drive_connection).and_return(google_drive_service)
    # allow(google_drive_service).to receive(:list_files).and_return(file_list)
  end

  describe "#check_connection" do
    before do
      allow(client).to receive(:create_drive_connection).and_return(google_drive_service)
    end
    context "when checking structured data connection" do
      it "throws a not implemented error" do
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed: Structured data is not supported yet")
      end
    end

    context "when checking unstructured data connection" do
      it "returns a succeeded connection status" do
        message = client.check_connection(unstructured_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when checking semistructured data connection" do
      it "returns a succeeded connection status" do
        message = client.check_connection(semistructured_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when checking connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:create_drive_connection).and_raise(StandardError, "Connection failed")
        message = client.check_connection(sync_config[:source][:connection_specification])
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    context "when discovering structured data" do
      it "throws a not implemented error" do
        expect(client).to receive(:handle_exception).with(
          an_instance_of(NotImplementedError),
          {
            context: "GOOGLE_DRIVE:DISCOVER:EXCEPTION",
            type: "error"
          }
        )
        client.discover(sync_config[:source][:connection_specification])
      end
    end

    context "when discovering unstructured data" do
      it "returns a catalog for unstructured data" do
        message = client.discover(unstructured_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        expect(message.catalog.streams).to be_an(Array)
        expect(message.catalog.streams.first).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(message.catalog.streams.first.name).to eq("unstructured")
      end
    end

    context "when discovering semistructured data" do
      it "returns a catalog for semistructured data" do
        message = client.discover(semistructured_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        expect(message.catalog.streams).to be_an(Array)
        expect(message.catalog.streams.first).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(message.catalog.streams.first.name).to eq("semistructured")
      end
    end

    context "when discovering fails" do
      it "handles exceptions during discovery" do
        allow(unstructured_config).to receive(:with_indifferent_access).and_raise(StandardError, "Discovery failed")
        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError),
          {
            context: "GOOGLE_DRIVE:DISCOVER:EXCEPTION",
            type: "error"
          }
        )
        client.discover(unstructured_config)
      end
    end
  end

  describe "#read" do
    before do
      allow(google_drive_service).to receive(:list_files).and_return(file_list)
      allow(google_drive_service).to receive(:get_file).and_return(expense_file)
      allow(Google::Apis::DriveV3::DriveService).to receive(:new).and_return(google_drive_service)
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(nil)
      allow(google_drive_service).to receive(:authorization=).and_return(nil)
    end
    context "when reading structured data" do
      it "throws a not implemented error" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        expect(client).to receive(:handle_exception).with(
          an_instance_of(NotImplementedError),
          {
            context: "GOOGLE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: s_config.sync_id,
            sync_run_id: s_config.sync_run_id
          }
        )
        client.read(s_config)
      end
    end

    context "when reading unstructured data" do
      it "returns records for unstructured data when list_files command is used" do
        sync_config[:source][:connection_specification] = unstructured_config
        sync_config[:model][:query] = "list_files"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:element_id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
      end
      it "returns records for unstructured data when download_file command is used" do
        sync_config[:source][:connection_specification] = unstructured_config
        sync_config[:model][:query] = "download_file expense_file.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:element_id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
      end

      it "raises an error when invalid command is used" do
        sync_config[:source][:connection_specification] = unstructured_config
        sync_config[:model][:query] = "invalid_command"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        expect(client).to receive(:handle_exception).with(
          an_instance_of(ArgumentError),
          {
            context: "GOOGLE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: s_config.sync_id,
            sync_run_id: s_config.sync_run_id
          }
        )
        client.read(s_config)
      end
    end

    context "when reading semistructured data" do
      it "returns records for semistructured data when list_files command is used" do
        sync_config[:source][:connection_specification] = semistructured_config
        sync_config[:model][:query] = "list_files"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:element_id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
      end
      it "returns records for semistructured data when download_file command is used" do
        sync_config[:source][:connection_specification] = semistructured_config
        sync_config[:model][:query] = "download_file expense_file.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:element_id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
      end
      it "raises an error when invalid command is used" do
        sync_config[:source][:connection_specification] = semistructured_config
        sync_config[:model][:query] = "invalid_command"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        expect(client).to receive(:handle_exception).with(
          an_instance_of(ArgumentError),
          {
            context: "GOOGLE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: s_config.sync_id,
            sync_run_id: s_config.sync_run_id
          }
        )
        client.read(s_config)
      end
    end

    context "when FILE_DOWNLOAD_PATH is set" do
      before do
        # Stub all ENV calls with a default value
        allow(ENV).to receive(:[]).and_return(nil)
        # Then specifically allow FILE_DOWNLOAD_PATH
        allow(ENV).to receive(:[]).with("FILE_DOWNLOAD_PATH").and_return("/custom/download/path")
      end
      it "raises an error for structured data" do
        sync_config[:model][:query] = "download_file expense_file.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        expect(client).to receive(:handle_exception).with(
          an_instance_of(NotImplementedError),
          {
            context: "GOOGLE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: s_config.sync_id,
            sync_run_id: s_config.sync_run_id
          }
        )
        client.read(s_config)
      end
      it "returns records for unstructured data" do
        sync_config[:source][:connection_specification] = unstructured_config
        sync_config[:model][:query] = "download_file expense_file.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
      end
      it "returns records for semistructured data" do
        sync_config[:source][:connection_specification] = semistructured_config
        sync_config[:model][:query] = "download_file expense_file.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)
        expect(records).to be_an(Array)
      end
    end
  end
end
