# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Destination
      module GoogleSheets
        include Multiwoven::Integrations::Core

        class Client < DestinationConnector
          prepend Multiwoven::Integrations::Core::Fullrefresher
          prepend Multiwoven::Integrations::Core::RateLimiter
          MAX_CHUNK_SIZE = 10_000

          def check_connection(connection_config)
            connection_config = connection_config.with_indifferent_access
            authorize_client(connection_config)
            fetch_google_spread_sheets(connection_config)
            success_status
          rescue StandardError => e
            failure_status(e)
          end

          def discover(connection_config)
            connection_config = connection_config.with_indifferent_access
            authorize_client(connection_config)
            spreadsheets = fetch_google_spread_sheets(connection_config)
            catalog = build_catalog_from_spreadsheets(spreadsheets, connection_config)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, {
                               context: "GOOGLE_SHEETS:CRM:DISCOVER:EXCEPTION",
                               type: "error"
                             })
          end

          def write(sync_config, records, action = "create")
            setup_write_environment(sync_config, action)
            process_record_chunks(records, sync_config)
          rescue StandardError => e
            handle_exception(e, {
                               context: "GOOGLE_SHEETS:CRM:WRITE:EXCEPTION",
                               type: "error",
                               sync_id: sync_config.sync_id,
                               sync_run_id: sync_config.sync_run_id
                             })
          end

          def clear_all_records(sync_config)
            setup_write_environment(sync_config, "clear")
            connection_specification = sync_config.destination.connection_specification.with_indifferent_access
            spreadsheet = fetch_google_spread_sheets(connection_specification)
            sheet_ids = spreadsheet.sheets.map(&:properties).map(&:sheet_id)

            delete_extra_sheets(sheet_ids)

            unless sheet_ids.empty?
              clear_response = clear_sheet_data(spreadsheet.sheets.first.properties.title)
              return control_message("Successfully cleared data.", "succeeded") if clear_response&.cleared_range
            end

            control_message("Failed to clear data.", "failed")
          rescue StandardError => e
            control_message(e.message, "failed")
          end

          private

          # To define the level of access granted to your app, you need to identify and declare authorization scopes which is provided by google scopse https://developers.google.com/sheets/api/scopes
          def authorize_client(config)
            credentials = config[:credentials_json]
            @client = Google::Apis::SheetsV4::SheetsService.new
            @client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
              json_key_io: StringIO.new(credentials.to_json),
              scope: GOOGLE_SHEETS_SCOPE
            )
          end

          # Extract spreadsheet id from the spreadsheet link and return the metadata for all the sheets
          def fetch_google_spread_sheets(connection_config)
            spreadsheet_id = extract_spreadsheet_id(connection_config[:spreadsheet_link])
            @client.get_spreadsheet(spreadsheet_id)
          end

          # dynamically builds catalog based on spreadsheet metadata
          def build_catalog_from_spreadsheets(spreadsheet, connection_config)
            catalog = build_catalog(load_catalog)
            @spreadsheet_id = extract_spreadsheet_id(connection_config[:spreadsheet_link])

            spreadsheet.sheets.each do |sheet|
              process_sheet_for_catalog(sheet, catalog)
            end

            catalog
          end

          # Builds catalog for the single spreadsheet based on column name
          def process_sheet_for_catalog(sheet, catalog)
            sheet_name, last_column_index = extract_sheet_properties(sheet)
            column_names = fetch_column_names(sheet_name, last_column_index)
            catalog.streams << generate_json_schema(column_names, sheet_name) if column_names
          end

          def extract_sheet_properties(sheet)
            [sheet.properties.title, sheet.properties.grid_properties.column_count]
          end

          def fetch_column_names(sheet_name, last_column_index)
            header_range = generate_header_range(sheet_name, last_column_index)
            spread_sheet_value(header_range)&.flatten
          end

          def spread_sheet_value(header_range)
            @spread_sheet_value ||= @client.get_spreadsheet_values(@spreadsheet_id, header_range).values
          end

          def generate_header_range(sheet_name, last_column_index)
            "#{sheet_name}!A1:#{column_index_to_letter(last_column_index)}1"
          end

          def column_index_to_letter(index)
            ("A".."ZZZ").to_a[index - 1]
          end

          def generate_json_schema(column_names, sheet_name)
            {
              name: sheet_name,
              action: "create",
              batch_support: true,
              batch_size: 10_000,
              json_schema: generate_properties_schema(column_names),
              supported_sync_modes: %w[incremental full_refresh]
            }.with_indifferent_access
          end

          def generate_properties_schema(column_names)
            properties = column_names.each_with_object({}) do |field, props|
              props[field] = { "type" => "string" }
            end

            { "$schema" => JSON_SCHEMA_URL, "type" => "object", "properties" => properties }
          end

          def setup_write_environment(sync_config, action)
            @action = sync_config.stream.action || action
            connection_specification = sync_config.destination.connection_specification.with_indifferent_access
            @spreadsheet_id = extract_spreadsheet_id(connection_specification[:spreadsheet_link])
            authorize_client(connection_specification)
          end

          def extract_spreadsheet_id(link)
            link[GOOGLE_SPREADSHEET_ID_REGEX, 1] || link
          end

          # Batch has a limit of sending 2MB data. So creating a chunk of records to meet that limit
          def process_record_chunks(records, sync_config)
            log_message_array = []
            write_success = 0
            write_failure = 0

            records.each_slice(MAX_CHUNK_SIZE) do |chunk|
              values = prepare_chunk_values(chunk, sync_config.stream)
              request, response = *update_sheet_values(values, sync_config.stream.name)
              write_success += values.size
              log_message_array << log_request_response("info", request, response)
            rescue StandardError => e
              handle_exception(e, {
                                 context: "GOOGLE_SHEETS:RECORD:WRITE:EXCEPTION",
                                 type: "error",
                                 sync_id: sync_config.sync_id,
                                 sync_run_id: sync_config.sync_run_id
                               })
              write_failure += chunk.size
              log_message_array << log_request_response("error", request, e.message)
            end
            tracking_message(write_success, write_failure, log_message_array)
          end

          # We need to format the data to adhere to google sheets API format. This converts the sync mapped data to 2D array format expected by google sheets API
          def prepare_chunk_values(chunk, stream)
            last_column_index = spread_sheet_value(stream.name).count
            fields = fetch_column_names(stream.name, last_column_index)

            chunk.map do |row|
              row_values = Array.new(fields.size, nil)
              row.each do |key, value|
                index = fields.index(key.to_s)
                row_values[index] = value if index
              end
              row_values
            end
          end

          def update_sheet_values(values, stream_name)
            row_count = spread_sheet_value(stream_name).count
            range = "#{stream_name}!A#{row_count + 1}"
            value_range = Google::Apis::SheetsV4::ValueRange.new(range: range, values: values)

            batch_update_request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(
              value_input_option: "RAW",
              data: [value_range]
            )

            # TODO: Remove & this is added for the test to pass we need
            response = @client&.batch_update_values(@spreadsheet_id, batch_update_request)
            [batch_update_request, response]
          end

          def load_catalog
            read_json(CATALOG_SPEC_PATH)
          end

          def delete_extra_sheets(sheet_ids)
            # Leave one sheet intact as a spreadsheet must have at least one sheet.
            # Delete all other sheets.
            (sheet_ids.length - 1).times do |i|
              request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
                requests: [{ delete_sheet: { sheet_id: sheet_ids[i + 1] } }]
              )
              @client.batch_update_spreadsheet(@spreadsheet_id, request)
            end
          end

          def clear_sheet_data(sheet_title)
            clear_request = Google::Apis::SheetsV4::ClearValuesRequest.new
            @client&.clear_values(@spreadsheet_id, "#{sheet_title}!A2:Z", clear_request)
          end

          def control_message(message, status)
            ControlMessage.new(
              type: "full_refresh",
              emitted_at: Time.now.to_i,
              status: ConnectionStatusType[status],
              meta: { detail: message }
            ).to_multiwoven_message
          end
        end
      end
    end
  end
end
