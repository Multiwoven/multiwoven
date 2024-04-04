# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::GoogleSheets::Client do # rubocop:disable Metrics/BlockLength
  include WebMock::API

  before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  let(:client) { described_class.new }
  let(:connection_config) do
    {
      "spreadsheet_link": "https://docs.google.com/spreadsheets/d/1Aa2KFKG4Q1glzj1bv7yJMAfTDJBbbBoJzrlN5vToFy0/edit#gid=0",
      "credentials_json": {
        "type": "service_account",
        "project_id": "multiwoven",
        "private_key_id": "private_key_id",
        "private_key": "private_key",
        "client_email": "multiwoven@multiwoven.iam.gserviceaccount.com",
        "client_id": "client_id",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "client_x509_cert_url",
        "universe_domain": "googleapis.com"
      }
    }
  end

  let(:google_sheet_osssoft_schema) do
    {
      "name" => "osssoft",
      "action" => "create",
      "json_schema" => {
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "type" => "object",
        "properties" => {
          "alternative" => {
            "type" => "string"
          },
          "category" => {
            "type" => "string"
          },
          "hide" => {
            "type" => "string"
          },
          "page" => {
            "type" => "string"
          },
          "stars" => {
            "type" => "string"
          },
          "text" => {
            "type" => "string"
          },
          "title" => {
            "type" => "string"
          },
          "url" => {
            "type" => "string"
          }
        }
      },
      "supported_sync_modes" => %w[
        full_refresh
        incremental
      ]
    }
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
        name: "Google Sheets",
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
        name: "osssoft",
        action: "create",
        request_rate_limit: 4,
        rate_limit_unit_seconds: 1,
        json_schema: google_sheet_osssoft_schema
      },
      sync_mode: "incremental",
      cursor_field: "timestamp",
      destination_sync_mode: "insert" }.with_indifferent_access
  end

  let(:records) do
    [
      build_record(true, 1),
      build_record(false, 5)
    ]
  end

  let(:google_sheets_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
  let(:spreadsheet) { instance_double(Google::Apis::SheetsV4::Spreadsheet) }

  before do
    allow(client).to receive(:authorize_client).and_return(true)
    color = Google::Apis::SheetsV4::Color.new(red: 1, green: 1, blue: 1)
    color_style = Google::Apis::SheetsV4::ColorStyle.new(rgb_color: color)
    cell_format = Google::Apis::SheetsV4::CellFormat.new(
      background_color: color,
      background_color_style: color_style,
      padding: Google::Apis::SheetsV4::Padding.new(top: 2, right: 3, bottom: 2, left: 3),
      text_format: Google::Apis::SheetsV4::TextFormat.new(
        bold: false,
        font_family: "arial,sans,sans-serif",
        font_size: 10,
        foreground_color: color,
        foreground_color_style: color_style,
        italic: false,
        strikethrough: false,
        underline: false
      ),
      vertical_alignment: "BOTTOM",
      wrap_strategy: "OVERFLOW_CELL"
    )

    theme_color_pair = Google::Apis::SheetsV4::ThemeColorPair.new(
      color: color_style,
      color_type: "TEXT"
    )

    spreadsheet_properties = Google::Apis::SheetsV4::SpreadsheetProperties.new(
      title: "oss software db",
      locale: "en_US",
      auto_recalc: "ON_CHANGE",
      default_format: cell_format,
      time_zone: "Europe/Istanbul",
      spreadsheet_theme: Google::Apis::SheetsV4::SpreadsheetTheme.new(
        primary_font_family: "Arial",
        theme_colors: [theme_color_pair]
      )
    )

    sheet_properties = Google::Apis::SheetsV4::SheetProperties.new(
      sheet_id: 12_345,
      title: "osssoft",
      grid_properties: Google::Apis::SheetsV4::GridProperties.new(row_count: 1000, column_count: 2)
    )

    sheet = Google::Apis::SheetsV4::Sheet.new(properties: sheet_properties)

    spreadsheet = Google::Apis::SheetsV4::Spreadsheet.new(
      properties: spreadsheet_properties,
      sheets: [sheet],
      spreadsheet_id: "spreadsheet_id",
      spreadsheet_url: "https://docs.google.com/spreadsheets/d/spreadsheet_id/edit"
    )

    allow(client).to receive(:fetch_google_spread_sheets).with(connection_config).and_return(spreadsheet)

    column_names = %w[alternative category hide page stars text title url]
    allow(client).to receive(:fetch_column_names).with("osssoft", 2).and_return(column_names)
  end

  describe "#check_connection" do
    context "when the connection is successful" do
      it "returns a successful connection status" do
        allow(client).to receive(:authenticate_client).and_return(true)

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when the connection fails" do
      it "returns a failed connection status with an error message" do
        allow(client).to receive(:authorize_client).and_raise(StandardError.new("connection failed"))

        response = client.check_connection(connection_config)

        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
        expect(response.connection_status.message).to eq("connection failed")
      end
    end
  end

  describe "#discover" do
    it "returns a catalog" do
      message = client.discover(connection_config)
      catalog = message.catalog
      expect(catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
      expect(catalog.request_rate_limit).to eql(300)
      expect(catalog.request_rate_limit_unit).to eql("minute")
      expect(catalog.request_rate_concurrency).to eql(10)
      expect(catalog.streams.count).to eql(1)
      expect(catalog.streams[0]["json_schema"]["properties"].keys).to eql(%w[alternative category hide page stars text title url])
    end
  end

  describe "#write" do
    context "when the write operation is successful" do
      before do
        update_values_response = Google::Apis::SheetsV4::UpdateValuesResponse.new(
          spreadsheet_id: "1Aa2KFKG4Q1glzj1bv7yJMAfTDJBbbBoJzrlN5vToFy0",
          updated_cells: 4,
          updated_columns: 2,
          updated_range: "osssoft!A10:D11",
          updated_rows: 2
        )

        batch_update_response = Google::Apis::SheetsV4::BatchUpdateValuesResponse.new(
          responses: [update_values_response],
          spreadsheet_id: "1Aa2KFKG4Q1glzj1bv7yJMAfTDJBbbBoJzrlN5vToFy0",
          total_updated_cells: 4,
          total_updated_columns: 2,
          total_updated_rows: 2,
          total_updated_sheets: 1
        )
        @client = Google::Apis::SheetsV4::SheetsService.new
        allow(@client).to receive(:batch_update_values)
          .with(@spreadsheet_id, an_instance_of(Google::Apis::SheetsV4::BatchUpdateValuesRequest))
          .and_return(batch_update_response)

        sample_response = %w[Value1 Value2]

        allow(client).to receive(:spread_sheet_value).with("osssoft").and_return(sample_response)

        @client = Google::Apis::SheetsV4::SheetsService.new
        batch_update_response = instance_double(Google::Apis::SheetsV4::BatchUpdateValuesResponse)
        allow(@client).to receive(:batch_update_values).and_return(batch_update_response)
      end

      it "increments the success count" do
        response = client.write(sync_config, records)

        expect(response.tracking.success).to eq(records.size)
        expect(response.tracking.failed).to eq(0)
      end
    end

    context "when the write operation fails" do
      before do
        batch_update_request = instance_double(Google::Apis::SheetsV4::BatchUpdateValuesRequest)
        allow(google_sheets_service).to receive(:batch_update_values)
          .with(@spreadsheet_id, batch_update_request)
          .and_raise(Google::Apis::ClientError.new("Invalid request"))
      end

      it "increments the failure count" do
        response = client.write(sync_config, records)

        expect(response.tracking.failed).to eq(records.size)
        expect(response.tracking.success).to eq(0)
      end
    end
  end

  describe "#meta_data" do
    it "serves it github image url as icon" do
      image_url = "https://raw.githubusercontent.com/Multiwoven/multiwoven-integrations/#{client.class::MAIN_BRANCH_SHA}/lib/multiwoven/integrations/destination/google_sheets/icon.svg"
      expect(client.send(:meta_data)[:data][:icon]).to eq(image_url)
    end
  end

  private

  def build_record(hide, page)
    {
      hide: hide,
      page: page
    }
  end

  def sync_config
    Multiwoven::Integrations::Protocol::SyncConfig.from_json(
      sync_config_json.to_json
    )
  end
  describe "#clear_all_records" do
    context "when clearing all records is successful" do
      it "clears data from the first sheet and deletes extra sheets" do
        expected_cleared_range = "test1!A1:Z1000"
        mock_clear_request = double(Google::Apis::SheetsV4::ClearValuesResponse)
        allow(mock_clear_request).to receive(:cleared_range).and_return(expected_cleared_range)
        allow(client).to receive(:clear_sheet_data).and_return(mock_clear_request)
        response = client.clear_all_records(sync_config)
        expect(response).to be_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.control.status).to eq("succeeded")
        expect(response.control.meta[:detail]).to include("Successfully cleared data")
      end
    end

    context "when there is an error clearing records" do
      it "returns a failure status in delete_extra_sheets" do
        allow(client).to receive(:delete_extra_sheets).and_raise(StandardError.new("Test Error"))
        response = client.clear_all_records(sync_config)
        expect(response).to be_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.control.status).to eq("failed")
        expect(response.control.meta[:detail]).to include("Test Error")
      end
      it "returns a failure status in clear_sheet_data" do
        allow(client).to receive(:clear_sheet_data).and_raise(StandardError.new("Test Error"))
        response = client.clear_all_records(sync_config)
        expect(response).to be_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.control.status).to eq("failed")
        expect(response.control.meta[:detail]).to include("Test Error")
      end
    end
  end
end
