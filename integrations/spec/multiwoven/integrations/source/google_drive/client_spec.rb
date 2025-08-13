# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::GoogleDrive::Client do
  let(:client) { described_class.new }
  let(:fields) { "files(id, name, parents, mimeType), nextPageToken" }
  let(:error_instance) { StandardError.new("Google Drive source error") }
  let(:amazon_textract_exception) { Aws::Textract::Errors::UnsupportedDocumentException.new(nil, "Document format not supported.") }

  let(:connection_config) do
    {
      credentials_json: {
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
      },
      options: {
        subfolders: false,
        fields: []
      }
    }
  end

  let(:sync_config_json) do
    {
      source: {
        name: "GoogleDrive",
        type: "source",
        connection_specification: connection_config
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
      "vendor_name" => { "type" => "string" }
    }
  end

  let(:google_drive_service) { instance_double(Google::Apis::DriveV3::DriveService) }
  let(:amazon_textract) { Aws::Textract::Client.new(stub_responses: true) }

  let(:analyze_expense_response) do
    Aws::Textract::Types::AnalyzeExpenseResponse.new(
      expense_documents: [Aws::Textract::Types::ExpenseDocument.new(
        summary_fields: [
          Aws::Textract::Types::ExpenseField.new(
            type: Aws::Textract::Types::ExpenseType.new(text: "VENDOR_NAME"),
            value_detection: Aws::Textract::Types::ExpenseDetection.new(text: "Vendor, Inc.")
          )
        ],
        line_item_groups: [
          Aws::Textract::Types::LineItemGroup.new(
            line_items: [
              Aws::Textract::Types::LineItemFields.new(
                line_item_expense_fields: [
                  Aws::Textract::Types::ExpenseField.new(
                    type: Aws::Textract::Types::ExpenseType.new(text: "PRODUCT_CODE"),
                    value_detection: Aws::Textract::Types::ExpenseDetection.new(text: "Product 0001")
                  )
                ]
              )
            ]
          )
        ]
      )]
    )
  end

  let(:expense_file) { Google::Apis::DriveV3::File.new(id: "1", name: "expense_file.pdf") }
  let(:specified_folder) { Google::Apis::DriveV3::File.new(id: "2", name: "folder") }

  before do
    client.instance_variable_set(:@options, connection_config[:options])
    allow(client).to receive(:create_connection).and_return(google_drive_service)
    allow(client).to receive(:create_aws_connection).and_return(amazon_textract)
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      before do
        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true, page_size: 1, q: "mimeType != 'application/vnd.google-apps.folder'" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [expense_file]))
      end
      it "returns a successful connection status" do
        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end
    end

    context "when the specified folder does not exist" do
      it "returns an unsuccesful connection status" do
        options = connection_config[:options]
        options[:folder] = "folder"
        client.instance_variable_set(:@options, options)

        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true,
                  q: "mimeType = 'application/vnd.google-apps.folder' and (name = 'folder')" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: []))

        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("failed")
        expect(result.message).to eq("Specified folder does not exist")
      end
    end

    context "when the connection is unsuccessful" do
      it "returns an unsucessful connection status" do
        allow(client).to receive(:create_connection).and_raise(error_instance)
        message = client.check_connection(connection_config)
        result = message.connection_status
        expect(result.status).to eq("failed")
      end
    end
  end

  describe "#discover" do
    context "when discover is succesful" do
      it "returns a catalog" do
        message = client.discover(connection_config)
        expect(message.catalog).to be_an(Multiwoven::Integrations::Protocol::Catalog)
        first_stream = message.catalog.streams.first
        expect(first_stream).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(first_stream.name).to eq("invoices")
        expect(first_stream.json_schema).to be_an(Hash)
        expect(first_stream.json_schema["type"]).to eq("object")
        expect(first_stream.json_schema["properties"]).to eq(catalog)
      end
    end
    context "when discover is unsucessful" do
      it "it handles exceptions during discovery" do
        allow(client).to receive(:build_catalog).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "GOOGLE_DRIVE:DISCOVER:EXCEPTION",
            type: "error"
          }
        )
        client.discover(connection_config)
      end
    end
  end

  describe "#read" do
    let(:sync_config) { Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config_json.to_json) }
    before do
      allow(amazon_textract).to receive(:analyze_expense).and_return(analyze_expense_response)
    end
    context "when read is successful" do
      before do
        existing_file = Google::Apis::DriveV3::File.new(id: "1", name: "existing_file.csv")
        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true, page_size: 50, q: "mimeType != 'application/vnd.google-apps.folder'" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [existing_file]))
        allow(google_drive_service).to receive(:get_file)
          .and_return(existing_file)
      end
      it "returns records succesfully for table selector" do
        records = client.read(sync_config)
        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data[:id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("existing_file.csv")
        expect(records.first.record.data[:vendor_name]).to eq("Vendor, Inc.")
        expect(records.first.record.data[:line_items]).to eq("[{\"item_number\":\"Product 0001\",\"item_description\":\"\",\"item_quantity\":\"\",\"item_price\":\"\",\"line_total\":\"\"}]")
      end

      it "returns records succesfully with specified folder" do
        options = connection_config[:options]
        options[:folder] = "folder"
        client.instance_variable_set(:@options, options)

        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true,
                  q: "mimeType = 'application/vnd.google-apps.folder' and (name = 'folder')" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [specified_folder]))

        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true,
                  q: "mimeType != 'application/vnd.google-apps.folder' and '2' in parents", page_size: 50 })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [expense_file]))

        records = client.read(sync_config)

        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data[:id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
        expect(records.first.record.data[:vendor_name]).to eq("Vendor, Inc.")
        expect(records.first.record.data[:line_items]).to eq("[{\"item_number\":\"Product 0001\",\"item_description\":\"\",\"item_quantity\":\"\",\"item_price\":\"\",\"line_total\":\"\"}]")
      end

      it "returns records successfuly with subfolders set to true" do
        options = connection_config[:options]
        options[:subfolders] = true
        client.instance_variable_set(:@options, options)

        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true,
                  q: "mimeType = 'application/vnd.google-apps.folder'" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [specified_folder]))

        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true,
                  q: "mimeType != 'application/vnd.google-apps.folder' and ('2' in parents)", page_size: 50 })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [expense_file]))

        records = client.read(sync_config)

        expect(records).to be_an(Array)
        expect(records.first.record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
        expect(records.first.record.data[:id]).to eq("1")
        expect(records.first.record.data[:file_name]).to eq("expense_file.pdf")
        expect(records.first.record.data[:vendor_name]).to eq("Vendor, Inc.")
        expect(records.first.record.data[:line_items]).to eq("[{\"item_number\":\"Product 0001\",\"item_description\":\"\",\"item_quantity\":\"\",\"item_price\":\"\",\"line_total\":\"\"}]")
      end
    end

    context "when read is unsuccesful" do
      before do
        allow(google_drive_service).to receive(:list_files)
          .with({ fields: fields, include_items_from_all_drives: true, supports_all_drives: true, page_size: 50, q: "mimeType != 'application/vnd.google-apps.folder'" })
          .and_return(Google::Apis::DriveV3::FileList.new(files: [expense_file]))
      end

      it "handles exception during reading" do
        allow(client).to receive(:create_connection).and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "GOOGLE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: "1",
            sync_run_id: nil
          }
        )
        client.read(sync_config)
      end

      it "handle unsupported document exception during expense analysis" do
        allow(google_drive_service).to receive(:get_file)
          .and_return(expense_file)
        allow(amazon_textract).to receive(:analyze_expense)
          .and_raise(amazon_textract_exception)
        expect(client).to receive(:handle_exception).with(
          amazon_textract_exception,
          {
            context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
            type: "error"
          }
        )
        client.read(sync_config)
      end

      it "handles unknown exception during expense analysis" do
        allow(google_drive_service).to receive(:get_file)
          .and_raise(error_instance)
        expect(client).to receive(:handle_exception).with(
          error_instance,
          {
            context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
            type: "error"
          }
        )
        client.read(sync_config)
      end
    end
  end
end
