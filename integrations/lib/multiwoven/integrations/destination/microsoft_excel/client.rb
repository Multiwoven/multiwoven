# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module MicrosoftExcel
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      prepend Multiwoven::Integrations::Core::RateLimiter
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        drive_id = create_connection(connection_config)
        if drive_id
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:EXCEL:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        connection_config = connection_config.with_indifferent_access
        token = connection_config[:token]
        drive_id = create_connection(connection_config)
        records = get_file(token, drive_id)
        records.each do |record|
          file_id = record[:id]
          record[:worksheets] = get_file_data(token, drive_id, file_id)
        end
        catalog = Catalog.new(streams: create_streams(records, catalog_json))
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "MICROSOFT:EXCEL:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        token = connection_config[:token]
        file_name = sync_config.stream.name.split(", ").first
        sheet_name = sync_config.stream.name.split(", ").last
        drive_id = create_connection(connection_config)
        excel_files = get_file(token, drive_id)
        worksheet = excel_files.find { |file| file[:name] == file_name }
        item_id = worksheet[:id]
        table = get_table(token, drive_id, item_id, sheet_name)
        write_url = format(MS_EXCEL_TABLE_ROW_WRITE_API, drive_id: drive_id, item_id: item_id, sheet_name: sheet_name,
                                                         table_name: table["name"])
        payload = { values: records.map(&:values) }
        process_write_request(write_url, payload, token, sync_config)
      end

      private

      def create_connection(connection_config)
        token = connection_config[:token]
        response = Multiwoven::Integrations::Core::HttpClient.request(
          MS_EXCEL_AUTH_ENDPOINT,
          HTTP_GET,
          headers: auth_headers(token)
        )
        JSON.parse(response.body)["id"]
      end

      def get_table(token, drive_id, item_id, sheet_name)
        table_url = format(MS_EXCEL_TABLE_API, drive_id: drive_id, item_id: item_id, sheet_name: sheet_name)
        response = Multiwoven::Integrations::Core::HttpClient.request(
          table_url,
          HTTP_GET,
          headers: auth_headers(token)
        )
        JSON.parse(response.body)["value"].first
      end

      def get_file(token, drive_id)
        url = format(MS_EXCEL_FILES_API, drive_id: drive_id)
        response = Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_GET,
          headers: auth_headers(token)
        )
        files = JSON.parse(response.body)["value"]
        excel_files = files.select { |file| file["name"].match(/\.(xlsx|xls|xlsm)$/) }
        excel_files.map { |file| { name: file["name"], id: file["id"] } }
      end

      def get_all_sheets(token, drive_id, item_id)
        base_url = format(MS_EXCEL_WORKSHEETS_API, drive_id: drive_id, item_id: item_id)
        worksheet_response = Multiwoven::Integrations::Core::HttpClient.request(
          base_url,
          HTTP_GET,
          headers: auth_headers(token)
        )
        JSON.parse(worksheet_response.body)["value"]
      end

      def get_file_data(token, drive_id, item_id)
        result = []
        worksheets_data = get_all_sheets(token, drive_id, item_id)
        worksheets_data.each do |sheet|
          sheet_name = sheet["name"]
          sheet_url = format(MS_EXCEL_SHEET_RANGE_API, drive_id: drive_id, item_id: item_id, sheet_name: sheet_name)

          sheet_response = Multiwoven::Integrations::Core::HttpClient.request(
            sheet_url,
            HTTP_GET,
            headers: auth_headers(token)
          )
          sheets_data = JSON.parse(sheet_response.body)
          column_names = if sheets_data.key?("error")
                           ["Column A"]
                         else
                           sheets_data["values"].first
                         end
          result << {
            sheet_name: sheet_name,
            column_names: column_names
          }
        end
        result
      end

      def create_streams(records, catalog_json)
        group_by_table(records).flat_map do |_, record|
          record.map do |_, r|
            Multiwoven::Integrations::Protocol::Stream.new(
              name: r[:workbook],
              action: StreamAction["fetch"],
              json_schema: convert_to_json_schema(r[:columns]),
              request_rate_limit: catalog_json["request_rate_limit"] || 60,
              request_rate_limit_unit: catalog_json["request_rate_limit_unit"] || "minute",
              request_rate_concurrency: catalog_json["request_rate_concurrency"] || 1
            )
          end
        end
      end

      def group_by_table(records)
        result = {}

        records.each_with_index do |entries, entries_index|
          entries[:worksheets].each_with_index do |sheet, entry_index|
            workbook_sheet = "#{entries[:name]}, #{sheet[:sheet_name]}"
            columns = sheet[:column_names].map do |column_name|
              column_name = "empty column" if column_name.empty?
              {
                column_name: column_name,
                data_type: "String",
                is_nullable: true
              }
            end
            result[entries_index] ||= {}
            result[entries_index][entry_index] = { workbook: workbook_sheet, columns: columns }
          end
        end
        result
      end

      def process_write_request(write_url, payload, token, sync_config)
        write_success = 0
        write_failure = 0
        log_message_array = []

        begin
          response = Multiwoven::Integrations::Core::HttpClient.request(
            write_url,
            HTTP_POST,
            payload: payload,
            headers: auth_headers(token)
          )
          if success?(response)
            write_success += 1
          else
            write_failure += 1
          end
          log_message_array << log_request_response("info", [HTTP_POST, write_url, payload], response)
        rescue StandardError => e
          handle_exception(e, {
                             context: "MICROSOFT:EXCEL:RECORD:WRITE:EXCEPTION",
                             type: "error",
                             sync_id: sync_config.sync_id,
                             sync_run_id: sync_config.sync_run_id
                           })
          write_failure += 1
          log_message_array << log_request_response("error", [HTTP_POST, write_url, payload], e.message)
        end

        tracking_message(write_success, write_failure, log_message_array)
      end
    end
  end
end
