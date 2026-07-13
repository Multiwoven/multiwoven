# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module OneDrive
    include Multiwoven::Integrations::Core
    class Client < UnstructuredSourceConnector
      SPREADSHEET_EXTENSIONS = %w[.csv .xlsx .xls .xlsm].freeze
      EXPIRED_ACCESS_TOKEN_ERROR_CODE = "InvalidAuthenticationToken"

      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        if unstructured_data?(connection_config)
          create_connection(connection_config)
          fetch_list_items
        else
          conn = create_connection(connection_config)
          @sync_id = "check_connection"
          files = spreadsheet_files(fetch_list_items)
          raise StandardError, "No spreadsheet files found" if files.empty?

          files.each { |file| describe_spreadsheet_file(conn, file) }
        end

        success_status
      rescue StandardError, NotImplementedError => e
        handle_exception(e, {
                           context: "ONE_DRIVE:CHECK_CONNECTION:EXCEPTION",
                           type: "error"
                         })
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access

        streams = if unstructured_data?(connection_config)
                    [create_unstructured_stream]
                  else
                    conn = create_connection(connection_config)
                    @sync_id = "discover"
                    files = spreadsheet_files(fetch_list_items)
                    raise StandardError, "No spreadsheet files found" if files.empty?

                    files.map { |file| discover_stream_for_file(conn, file) }
                  end
        catalog = Catalog.new(streams: streams)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "ONE_DRIVE:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        @connector_instance = sync_config&.source&.connector_instance

        return handle_unstructured_data(sync_config) if unstructured_data?(connection_config)

        conn = create_connection(connection_config)

        @connection_config = connection_config
        @sync_id = sync_config.sync_id

        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        query(conn, query)
      rescue StandardError => e
        handle_exception(e, {
                           context: "ONE_DRIVE:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def load_connection_config(connection_config)
        @user_name = connection_config[:user_name]
        @tenant_id = connection_config[:tenant_id]
        @client_id = connection_config[:client_id]
        @client_secret = connection_config[:client_secret]
        @data_type = connection_config[:data_type]
        @file_name = connection_config[:file_name]
        @share_url = connection_config[:share_url]
        stored_token = @connector_instance&.configuration&.dig("access_token")
        @access_token = stored_token.presence || refresh_access_token
      end

      def create_connection(connection_config)
        raise ArgumentError, "User Name or Share URL is required" unless connection_config[:share_url].present? || connection_config[:user_name].present?

        load_connection_config(connection_config)

        if @share_url.present?
          @drive_id = shared_folder_reference[:drive_id]
        else
          response = microsoft_graph_request(user_drive_url)
          raise graph_api_error(response.body) unless success?(response)

          @drive_id = JSON.parse(response.body)["id"]
        end

        return if @data_type.to_s == "unstructured"

        duckdb_connection
      end

      def refresh_access_token
        @access_token = fetch_access_token
        persist_access_token(@access_token)
        @access_token
      end

      def persist_access_token(token)
        return unless @connector_instance&.configuration

        config = @connector_instance.configuration
        config = {} unless config.is_a?(Hash)
        @connector_instance.update!(configuration: config.merge("access_token" => token))
      end

      def microsoft_graph_request(url)
        response = graph_http_get(url)
        return response unless expired_access_token_error?(response.body)

        refresh_access_token
        graph_http_get(url)
      end

      def graph_http_get(url)
        Multiwoven::Integrations::Core::HttpClient.request(
          url,
          HTTP_GET,
          headers: auth_headers(@access_token)
        )
      end

      def fetch_access_token
        response = Multiwoven::Integrations::Core::HttpClient.request(
          format(MICROSOFT_GRAPH_TOKEN_URL, tenant_id: @tenant_id),
          HTTP_POST,
          payload: form_urlencoded_payload(
            client_id: @client_id,
            client_secret: @client_secret,
            scope: MICROSOFT_GRAPH_SCOPE,
            grant_type: "client_credentials"
          ),
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        )
        raise graph_api_error(response.body) unless success?(response)

        JSON.parse(response.body)["access_token"]
      end

      def handle_unstructured_data(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        command = sync_config.model.query.strip
        create_connection(connection_config)

        case command
        when LIST_FILES_CMD
          list_files_in_folder(connection_config)
        when /^#{DOWNLOAD_FILE_CMD}\s+(.+)$/
          file_name = ::Regexp.last_match(1).strip
          file_name = file_name.gsub(/^["']|["']$/, "")
          download_unstructured_file(connection_config, file_name, sync_config.sync_id)
        else
          raise ArgumentError, "Invalid command. Supported commands: #{LIST_FILES_CMD}, #{DOWNLOAD_FILE_CMD} <file_path>"
        end
      end

      def list_files_in_folder(_connection_config)
        files_in_folder.map do |file|
          RecordMessage.new(
            data: {
              element_id: file["id"],
              file_name: file["name"],
              file_path: file["name"],
              size: file["size"],
              file_type: File.extname(file["name"]).sub(".", ""),
              created_date: file["createdDateTime"],
              modified_date: file["lastModifiedDateTime"],
              text: ""
            },
            emitted_at: Time.now.to_i
          ).to_multiwoven_message
        end
      end

      def download_unstructured_file(_connection_config, file_path, sync_id)
        file_name = resolve_download_file_name(file_path)
        file_item = files_in_folder.find { |item| item["name"] == file_name }
        raise StandardError, "File not found." if file_item.nil?

        local_path = download_file_to_local(
          file_name,
          sync_id,
          item_id: file_item["id"],
          drive_id: file_item.dig("parentReference", "driveId")
        )

        [RecordMessage.new(
          data: {
            element_id: file_item["id"],
            local_path: local_path,
            file_name: file_name,
            file_path: file_name,
            size: file_item["size"],
            file_type: File.extname(file_name).sub(".", ""),
            created_date: file_item["createdDateTime"],
            modified_date: file_item["lastModifiedDateTime"],
            text: ""
          },
          emitted_at: Time.now.to_i
        ).to_multiwoven_message]
      end

      def files_in_folder
        records = fetch_list_items
        records["value"].select do |item|
          item["folder"].blank? && matching_file_name?(item["name"])
        end
      end

      def resolve_download_file_name(file_path)
        return File.basename(file_path) unless file_path.to_s.start_with?("http")

        @file_name.to_s.strip.presence || File.basename(file_path)
      end

      def matching_file_name?(name)
        configured_name = @file_name.to_s.strip
        configured_name.blank? || configured_name == name
      end

      def discover_stream_for_file(conn, file)
        describe_results = describe_spreadsheet_file(conn, file)
        columns = build_discover_columns(describe_results)

        Multiwoven::Integrations::Protocol::Stream.new(
          name: stream_name_for(file["name"]),
          action: StreamAction["fetch"],
          json_schema: convert_to_json_schema(columns)
        )
      end

      def describe_spreadsheet_file(conn, file)
        local_file = nil
        file_name = file["name"]
        local_file = download_file_to_local(
          file_name,
          @sync_id,
          item_id: file["id"],
          drive_id: file.dig("parentReference", "driveId")
        )
        duckdb_file = read_local_file(conn, file_name, local_file)
        get_results(conn, "DESCRIBE SELECT * FROM #{duckdb_file};")
      ensure
        cleanup_ephemeral_download(local_file)
      end

      def build_discover_columns(describe_results)
        describe_results.map do |row|
          {
            column_name: row["column_name"],
            type: column_schema_helper(row["column_type"])
          }
        end
      end

      # Maps DuckDB column types before convert_to_json_schema. Note that map_type_to_json_schema
      # only recognizes "NUMBER" and "vector", so integer/number/boolean here still become "string"
      # in the emitted json_schema (inherited from amazon_s3; not a typed-schema connector).
      def column_schema_helper(column_type)
        case column_type
        when "VARCHAR", "BIT", "DATE", "TIME", "TIMESTAMP", "UUID"
          "string"
        when "DOUBLE"
          "number"
        when "BIGINT", "HUGEINT", "INTEGER", "SMALLINT"
          "integer"
        when "BOOLEAN"
          "boolean"
        end
      end

      def query(connection, query)
        local_file = nil
        file_name = extract_file_name_from_query(query)
        local_file = download_file_to_local(file_name, @sync_id)

        file = read_local_file(connection, file_name, local_file)
        query = apply_local_file_to_query(query, file)
        get_results(connection, query).map do |row|
          RecordMessage.new(data: row, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      ensure
        cleanup_ephemeral_download(local_file)
      end

      def extract_file_name_from_query(sql_query)
        match = sql_query.match(
          /\bFROM\s+(?:[`"]([^`"]+)[`"]|'([^']+)'|([^\s;]+))/i
        )

        match&.captures&.compact&.first ||
          raise(ArgumentError, "Could not extract file name from query")
      end

      def duckdb_connection
        conn = DuckDB::Database.open.connect
        conn.execute(INSTALL_HTTPFS_QUERY)
        conn
      end

      def read_local_file(conn, file_name, local_file)
        escaped_path = local_file.gsub("'", "''")

        case File.extname(file_name).downcase
        when ".csv"
          "read_csv_auto('#{escaped_path}')"
        when ".xlsx", ".xls", ".xlsm"
          conn.execute("INSTALL excel; LOAD excel;")
          "read_xlsx('#{escaped_path}')"
        else
          raise ArgumentError, "Unsupported file type: #{file_name}"
        end
      end

      def apply_local_file_to_query(sql_query, file)
        sql_query.sub(/\bFROM\s+(?:`[^`]+`|"[^"]+"|'[^']+'|[^\s;]+)/i, "FROM #{file}")
      end

      def get_results(conn, sql_query)
        hash_array_values(conn.query(sql_query))
      end

      def hash_array_values(results)
        keys = results.columns.map(&:name)
        results.map do |row|
          Hash[keys.zip(row)]
        end
      end

      def download_file_to_local(file_name, sync_id, item_id: nil, drive_id: nil)
        local_file = local_download_path(file_name, sync_id)
        FileUtils.mkdir_p(File.dirname(local_file))

        response = fetch_file_content(file_content_url(file_name, item_id: item_id, drive_id: drive_id))
        raise graph_api_error(response.body) unless success?(response)

        File.binwrite(local_file, response.body)
        local_file
      rescue StandardError => e
        raise StandardError, "Failed to download file #{file_name}: #{e.message}"
      end

      def local_download_path(file_name, sync_id)
        download_path = ENV["FILE_DOWNLOAD_PATH"]
        if download_path
          File.join(download_path, "syncs", sync_id, File.basename(file_name))
        else
          @temp_download_dir ||= Dir.mktmpdir("one_drive_#{sync_id}")
          File.join(@temp_download_dir, File.basename(file_name))
        end
      end

      def cleanup_ephemeral_download(local_file)
        return if local_file.blank? || ENV["FILE_DOWNLOAD_PATH"].present?
        return unless ephemeral_download?(local_file)

        File.delete(local_file) if File.exist?(local_file)
      end

      def ephemeral_download?(local_file)
        @temp_download_dir.present? && local_file.start_with?(@temp_download_dir)
      end

      def file_content_url(file_name, item_id: nil, drive_id: nil)
        if item_id.present?
          resolved_drive_id = drive_id || @drive_id
          return "#{drive_item_url(resolved_drive_id, item_id)}/content"
        end

        if @share_url.present? && shared_folder_reference[:is_file]
          shared = shared_folder_reference
          return "#{drive_item_url(shared[:drive_id], shared[:item_id])}/content"
        end

        "#{single_file_item_url(file_name)}:/content"
      end

      def single_file_item_url(file_name)
        encoded_file = URI::DEFAULT_PARSER.escape(file_name)

        if @share_url.present?
          shared = shared_folder_reference
          "#{drive_item_url(shared[:drive_id], shared[:item_id])}:/#{encoded_file}"
        else
          "#{drive_root_url(@drive_id)}:/#{encoded_file}"
        end
      end

      def list_items_url
        if @share_url.present?
          "#{share_item_url}/children"
        else
          "#{drive_root_url(@drive_id)}/children"
        end
      end

      def user_drive_url
        format(MICROSOFT_GRAPH_USER_DRIVE_URL, user_name: @user_name)
      end

      def share_item_url
        share_id = encode_sharing_url(@share_url)
        format(MICROSOFT_GRAPH_SHARE_ITEM_URL, share_id: share_id)
      end

      def drive_item_url(drive_id, item_id)
        format(MICROSOFT_GRAPH_DRIVE_ITEM_URL, drive_id: drive_id, item_id: item_id)
      end

      def drive_root_url(drive_id)
        "#{MICROSOFT_GRAPH_BASE}/drives/#{drive_id}/root"
      end

      def fetch_file_content(url)
        response = microsoft_graph_request(url)
        return response unless response.is_a?(Net::HTTPRedirection)

        Multiwoven::Integrations::Core::HttpClient.request(response["location"], HTTP_GET)
      end

      def fetch_list_items
        return { "value" => [fetch_single_file_item] } if single_file_mode?

        return { "value" => [fetch_shared_item_metadata] } if @share_url.present? && shared_folder_reference[:is_file]

        paginated_graph_collection(list_items_url)
      end

      def fetch_shared_item_metadata
        response = microsoft_graph_request(share_item_url)
        raise graph_api_error(response.body) unless success?(response)

        JSON.parse(response.body)
      end

      def single_file_mode?
        @file_name.to_s.strip.present? && @data_type.to_s == "unstructured"
      end

      def fetch_single_file_item
        return fetch_shared_item_metadata if @share_url.present? && shared_folder_reference[:is_file]

        response = microsoft_graph_request(single_file_item_url(@file_name))
        raise graph_api_error(response.body) unless success?(response)

        JSON.parse(response.body)
      end

      def paginated_graph_collection(url)
        items = []
        next_url = url

        loop do
          response = microsoft_graph_request(next_url)
          raise graph_api_error(response.body) unless success?(response)

          page = JSON.parse(response.body)
          items.concat(page["value"] || [])
          next_url = page["@odata.nextLink"]
          break if next_url.blank?
        end

        { "value" => items }
      end

      def shared_folder_reference
        @shared_folder_reference ||= begin
          response = microsoft_graph_request(share_item_url)
          raise graph_api_error(response.body) unless success?(response)

          item = JSON.parse(response.body)
          drive_id = item.dig("parentReference", "driveId")
          item_id = item["id"]
          raise StandardError, "Could not resolve shared folder drive reference" if drive_id.blank? || item_id.blank?

          { drive_id: drive_id, item_id: item_id, is_file: item["file"].present? }
        end
      end

      def spreadsheet_files(records)
        records["value"].select do |record|
          record["folder"].blank? &&
            SPREADSHEET_EXTENSIONS.include?(File.extname(record["name"].to_s).downcase) &&
            matching_file_name?(record["name"])
        end
      end

      # Keep the file extension in the stream name — TableSelector generates
      # `SELECT * FROM ${stream.name}`, and read_local_file keys off File.extname.
      def stream_name_for(file_name)
        File.basename(file_name)
      end

      def encode_sharing_url(url)
        encoded = Base64.strict_encode64(url).tr("+/", "-_").delete("=")
        "u!#{encoded}"
      end

      def graph_api_error(response_body)
        parsed = JSON.parse(response_body)
        error = parsed["error"]

        message = if error.is_a?(Hash)
                    "#{error["code"]}: #{error["message"]}"
                  elsif error.is_a?(String)
                    description = parsed["error_description"]
                    description.present? ? "#{error}: #{description}" : error
                  else
                    response_body
                  end

        StandardError.new(message)
      rescue JSON::ParserError, TypeError
        StandardError.new(response_body.to_s)
      end

      def expired_access_token_error?(response_body)
        error = JSON.parse(response_body)["error"]
        return false unless error.is_a?(Hash)

        error["code"] == EXPIRED_ACCESS_TOKEN_ERROR_CODE
      rescue JSON::ParserError
        false
      end

      # HttpClient.request always calls payload.to_json.
      # Microsoft OAuth token endpoints require
      # application/x-www-form-urlencoded bodies instead of JSON.
      # This wrapper overrides to_json so HttpClient sends a
      # form-encoded string rather than a JSON document.
      def form_urlencoded_payload(fields)
        payload = Object.new
        payload.define_singleton_method(:to_json) do |*_args|
          URI.encode_www_form(fields)
        end
        payload
      end
    end
  end
end
