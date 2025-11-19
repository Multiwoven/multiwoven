# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleDrive
    include Multiwoven::Integrations::Core

    FIELDS = "files(id, name, parents, mimeType, fileExtension, size, createdTime, modifiedTime), nextPageToken"
    MAX_PER_PAGE = 1000
    MIMETYPE_GOOGLE_DRIVE_FOLDER = "mimeType = 'application/vnd.google-apps.folder'"

    class Client < UnstructuredSourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access

        if unstructured_data?(connection_config) || semistructured_data?(connection_config)
          create_drive_connection(connection_config)
        else
          create_connection(connection_config)
        end
        success_status
      rescue StandardError, NotImplementedError => e
        failure_status(e)
      end

      def discover(connection_config)
        connection_config = connection_config.with_indifferent_access
        streams = if unstructured_data?(connection_config)
                    [create_unstructured_stream]
                  elsif semistructured_data?(connection_config)
                    [create_semistructured_stream]
                  else
                    raise NotImplementedError, "Discovery failed: Structured data is not supported yet"
                  end
        catalog = Catalog.new(streams: streams)
        catalog.to_multiwoven_message
      rescue StandardError, NotImplementedError => e
        handle_exception(e, {
                           context: "GOOGLE_DRIVE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access

        return handle_unstructured_data(sync_config) if unstructured_data?(connection_config) || semistructured_data?(connection_config)

        raise NotImplementedError, "Read failed: Structured data is not supported yet"
      rescue StandardError, NotImplementedError => e
        handle_exception(e, {
                           context: "GOOGLE_DRIVE:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        raise NotImplementedError, "Connection failed: Structured data is not supported yet"
      end

      def create_drive_connection(connection_config)
        credentials = connection_config[:credentials_json]
        @google_drive = Google::Apis::DriveV3::DriveService.new
        @google_drive.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(credentials.to_json),
          scope: GOOGLE_SHEETS_SCOPE
        )
      end

      def handle_unstructured_data(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        folder_name = connection_config[:folder_name]
        command = sync_config.model.query.strip
        create_drive_connection(connection_config)

        case command
        when LIST_FILES_CMD
          list_files_in_folder(folder_name)
        when /^#{DOWNLOAD_FILE_CMD}\s+(.+)$/
          file_name = ::Regexp.last_match(1).strip
          file_name = file_name.gsub(/^["']|["']$/, "") # Remove leading/trailing quotes
          download_file_to_local(file_name, sync_config.sync_id)
        else
          raise ArgumentError, "Invalid command. Supported commands: #{LIST_FILES_CMD}, #{DOWNLOAD_FILE_CMD} <file_path>"
        end
      end

      def list_files_in_folder(folder_name)
        query = build_query(folder_name)
        records = get_files(@google_drive, query, 10_000, 0)
        records.map do |row|
          RecordMessage.new(
            data: {
              element_id: row.id,
              file_name: row.name,
              file_path: row.name,
              size: row.size,
              file_type: row.file_extension,
              created_date: row.created_time,
              modified_date: row.modified_time,
              text: ""
            },
            emitted_at: Time.now.to_i
          ).to_multiwoven_message
        end
      end

      def download_file_to_local(file_name, sync_id)
        download_path = ENV["FILE_DOWNLOAD_PATH"]
        file = if download_path
                 File.join(download_path, "syncs", sync_id, File.basename(file_name))
               else
                 Tempfile.new(["google_drive_file_syncs_#{sync_id}", File.extname(file_name)]).path
               end

        # Escape single quotes to prevent query injection
        escaped_name = file_name.gsub("'", "\\\\'")
        query = "mimeType != 'application/vnd.google-apps.folder' and name = '#{escaped_name}'"

        records = get_files(@google_drive, query, 1, 0)
        raise StandardError, "File not found." if records.empty?

        @google_drive.get_file(records.first.id, download_dest: file)

        [RecordMessage.new(
          data: {
            element_id: records.first.id,
            local_path: file,
            file_name: file_name,
            file_path: file_name,
            size: records.first.size,
            file_type: records.first.file_extension,
            created_date: records.first.created_time,
            modified_date: records.first.modified_time,
            text: ""
          },
          emitted_at: Time.now.to_i
        ).to_multiwoven_message]
      rescue StandardError => e
        raise StandardError, "Failed to download file #{file_name}: #{e.message}"
      end

      def build_query(folder_name)
        raise ArgumentError, "Folder name is required" if folder_name.blank?

        # Escape single quotes to prevent query injection
        escaped_folder = folder_name.gsub("'", "\\\\'")
        folder_query = "#{MIMETYPE_GOOGLE_DRIVE_FOLDER} and (name = '#{escaped_folder}')"
        response = @google_drive.list_files(include_items_from_all_drives: true, supports_all_drives: true, q: folder_query, fields: FIELDS)
        raise ArgumentError, "Specified folder does not exist" if response.files.empty?

        parent_id = response.files.first.id
        "'#{parent_id}' in parents"
      end

      def get_files(client, query, limit, offset)
        total_fetched = 0
        result = []

        return result if offset.positive? && !@next_page_token

        while total_fetched < limit
          batch_limit = [MAX_PER_PAGE, limit - total_fetched].min
          response = if @next_page_token
                       client.list_files(include_items_from_all_drives: true, supports_all_drives: true, q: query, fields: FIELDS, page_size: batch_limit, page_token: @next_page_token)
                     else
                       client.list_files(include_items_from_all_drives: true, supports_all_drives: true, q: query, fields: FIELDS, page_size: batch_limit)
                     end
          break if response.files.empty?

          result.push(*response.files)
          @next_page_token = response.next_page_token
          break unless response.next_page_token

          total_fetched += response.files.size
        end

        result
      end
    end
  end
end
