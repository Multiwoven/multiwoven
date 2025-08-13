# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module GoogleDrive
    include Multiwoven::Integrations::Core

    FIELDS = "files(id, name, parents, mimeType), nextPageToken"
    MAX_PER_PAGE = 1000
    MIMETYPE_GOOGLE_DRIVE_FOLDER = "mimeType = 'application/vnd.google-apps.folder'"

    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        client = create_connection(connection_config)
        build_query(client)
        success_status
      rescue StandardError => e
        failure_status(e)
      end

      def discover(_connection_config)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "GOOGLE_DRIVE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification.with_indifferent_access
        client = create_connection(connection_config)
        query = sync_config.model.query
        query = batched_query(query, sync_config.limit, sync_config.offset) unless sync_config.limit.nil? && sync_config.offset.nil?
        records = query(client, query)
        analyze_expenses(client, records)
      rescue StandardError => e
        handle_exception(e, {
                           context: "GOOGLE_DRIVE:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def query(client, query)
        limit = 0
        offset = 0
        query = query.gsub("\n", " ").gsub(/\s+/, " ")
        limit = query.match(/LIMIT (\d+)/)[1].to_i if query.include? "LIMIT"
        offset = query.match(/OFFSET (\d+)/)[1].to_i if query.include? "OFFSET"
        query = query.match(/\((.*)\) AS/)[1] if query.include? "AS subquery"
        columns = select_columns(query)

        google_drive_query = build_query(client)
        files = get_files(client, google_drive_query, limit, offset)
        files.map do |file|
          RecordMessage.new(data: prepare_invoice(file, columns), emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      # Reads files from Google Drive and sends them to Amazon Textract for analysis
      def analyze_expenses(client, records)
        textract = create_aws_connection
        results = []
        records.each do |record|
          invoice = record.record.data
          begin
            byte_stream = StringIO.new
            client.get_file(invoice["id"], download_dest: byte_stream)
            byte_stream.rewind
            analysis = textract.analyze_expense(document: { bytes: byte_stream.read })
            invoice = extract_invoice_data(invoice, analysis)
          rescue Aws::Textract::Errors::UnsupportedDocumentException => e
            invoice[:exception] = "Document format not supported." if invoice.key?(:exception)
            handle_exception(e, {
                               context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
                               type: "error"
                             })
          rescue StandardError => e
            invoice[:exception] = e.message if invoice.key?(:exception)
            handle_exception(e, {
                               context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
                               type: "error"
                             })
          end
          results.append(RecordMessage.new(data: invoice, emitted_at: Time.now.to_i).to_multiwoven_message)
        end
        results
      end

      def build_query(client)
        query = "mimeType != 'application/vnd.google-apps.folder'"

        if @options[:folder]
          folder_query = "#{MIMETYPE_GOOGLE_DRIVE_FOLDER} and (name = '#{@options[:folder]}')"
          response = client.list_files(include_items_from_all_drives: true, supports_all_drives: true, q: folder_query, fields: FIELDS)
          raise "Specified folder does not exist" if response.files.empty?

          parent_id = response.files.first.id
          parents_query = "'#{parent_id}' in parents"
        end

        if @options[:subfolders]
          subfolders_query = MIMETYPE_GOOGLE_DRIVE_FOLDER
          subfolders_query += "and #{parents_query}" if parents_query
          response = client.list_files(include_items_from_all_drives: true, supports_all_drives: true, q: subfolders_query, fields: FIELDS)
          subfolders_ids = response.files.map { |file| "'#{file.id}'" }
          parents_query = "(#{subfolders_ids.join(" in parents or ")} in parents)"
        end

        query += " and mimeType = '#{@options[:file_type]}'" if @options[:file_type]
        query += " and #{parents_query}" if parents_query
        query
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

      def select_columns(query)
        columns = query.match(/SELECT (.*) FROM/)[1]
        all_columns = %w[line_items id file_name] + TEXTRACT_SUMMARY_FIELDS.keys
        @options[:fields] = all_columns if @options[:fields].empty?

        return @options[:fields] if columns.include?("*")

        columns = columns.split(",").map(&:strip)
        raise "Column(s) #{(columns - all_columns).join(", ")} not valid." if (columns - all_columns).length.positive?

        columns & all_columns
      end

      def prepare_invoice(file, columns)
        invoice = {}
        columns.each { |column| invoice[column] = "" if TEXTRACT_SUMMARY_FIELDS.key?(column) }
        invoice["line_items"] = [] if columns.any?("line_items")
        invoice["id"] = file.id if columns.any?("id")
        invoice["file_name"] = file.name if columns.any?("file_name")
        invoice["exception"] = "" if columns.any?("exception")
        invoice
      end

      def create_connection(connection_config)
        @options = connection_config[:options]
        credentials = connection_config[:credentials_json]
        client = Google::Apis::DriveV3::DriveService.new
        client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(credentials.to_json),
          scope: GOOGLE_SHEETS_SCOPE
        )
        client
      end

      def create_aws_connection
        region = ENV["AWS_REGION"]
        access_key_id = ENV["AWS_ACCESS_KEY_ID"]
        secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
        credentials = Aws::Credentials.new(access_key_id, secret_access_key)
        Aws::Textract::Client.new(region: region, credentials: credentials)
      end

      def extract_invoice_data(invoice, results)
        expense_document = results.expense_documents[0]
        (invoice.keys & TEXTRACT_SUMMARY_FIELDS.keys).each do |key|
          invoice[key] = extract_field_value(expense_document.summary_fields, TEXTRACT_SUMMARY_FIELDS[key])
        end

        if invoice.key?("line_items")
          expense_document.line_item_groups.each do |line_item_group|
            line_item_group.line_items.each do |line_item|
              extracted_line_item = {}
              TEXTRACT_LINE_ITEMS_FIELDS.each_key do |key|
                extracted_line_item[key] = extract_field_value(line_item.line_item_expense_fields, TEXTRACT_LINE_ITEMS_FIELDS[key])
              end
              invoice["line_items"] << extracted_line_item
            end
          end
        end
        invoice["line_items"] = invoice["line_items"].to_json
        invoice.transform_keys(&:to_sym)
      end

      def extract_field_value(fields, selector)
        selected_field = fields.select { |field| field.type.text == selector }.first
        selected_field ? selected_field.value_detection.text : ""
      end
    end
  end
end
