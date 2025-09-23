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
        process_files(client, records)
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
      def process_files(client, records)
        textract = create_aws_textract_connection
        results = []
        records.each do |record|
          invoice = record.record.data
          begin
            temp_file = Tempfile.new(invoice["file_name"])
            client.get_file(invoice["id"], download_dest: temp_file.path)

            reader = PDF::Reader.new(temp_file)
            page_count = reader.page_count

            analysis = if page_count > 1
                         start_expense_analysis(invoice["file_name"], temp_file)
                       else
                         [textract.analyze_expense(document: { bytes: File.binread(temp_file.path) })]
                       end

            invoice = extract_invoice_data(invoice, analysis)
          rescue Aws::Textract::Errors::UnsupportedDocumentException => e
            invoice["exception"] = e.message if invoice.key?("exception")
            handle_exception(e, {
                               context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
                               type: "error"
                             })
          rescue StandardError => e
            handle_exception(e, {
                               context: "GOOGLE_DRIVE:READ:EXTRACT:EXCEPTION",
                               type: "error"
                             })
          end
          results.append(RecordMessage.new(data: invoice, emitted_at: Time.now.to_i).to_multiwoven_message)
        end
        results
      end

      def start_expense_analysis(file_name, temp_file)
        bucket_name = ENV["TEXTRACT_BUCKET_NAME"]
        s3_client = create_aws_s3_connection
        textract = create_aws_textract_connection

        s3_client.put_object(
          bucket: bucket_name,
          key: file_name,
          body: temp_file
        )

        resp = textract.start_expense_analysis(
          document_location: {
            s3_object: {
              bucket: bucket_name,
              name: file_name
            }
          }
        )

        job_id = resp.job_id
        all_pages = []
        next_token = nil

        loop do
          result = textract.get_expense_analysis(
            job_id: job_id,
            next_token: next_token
          )

          status = result.job_status
          if status == "SUCCEEDED"
            all_pages << result
            next_token = result.next_token
            break unless next_token
          elsif %w[FAILED PARTIAL_SUCCESS].include?(status)
            raise "Textract job ended with status: #{status}"
          else
            sleep 2 # still IN_PROGRESS; wait briefly and try again
          end
        end
        all_pages
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
        all_columns = %w[line_items id file_name exception results] + TEXTRACT_SUMMARY_FIELDS.keys
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
        invoice["results"] = {} if columns.any?("results")
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

      # TODO: Refactor (extract) code for Amazon Textract
      def create_aws_credentials
        access_key_id = ENV["AWS_ACCESS_KEY_ID"]
        secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
        Aws::Credentials.new(access_key_id, secret_access_key)
      end

      def create_aws_textract_connection
        region = ENV["AWS_REGION"]
        credentials = create_aws_credentials
        Aws::Textract::Client.new(region: region, credentials: credentials)
      end

      def create_aws_s3_connection
        region = ENV["AWS_REGION"]
        credentials = create_aws_credentials
        Aws::S3::Client.new(region: region, credentials: credentials)
      end

      def extract_invoice_data(invoice, results)
        invoice = extract_summary_fields(invoice, results)
        invoice = extract_line_items(invoice, results)
        invoice["results"] = results.to_json if invoice.key?("results")
        invoice.transform_keys(&:to_sym)
      end

      def extract_summary_fields(invoice, results)
        document = results[0].expense_documents[0]
        (invoice.keys & TEXTRACT_SUMMARY_FIELDS.keys).each do |key|
          invoice[key] = extract_field_value(document.summary_fields, TEXTRACT_SUMMARY_FIELDS[key])
        end
        invoice
      end

      def extract_line_items(invoice, results)
        if invoice.key?("line_items")
          results.each do |result|
            result.expense_documents.each do |expense_document|
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
          end
        end
        invoice["line_items"] = invoice["line_items"].to_json
        invoice
      end

      def extract_field_value(fields, selector)
        selected_field = fields.select { |field| field.type.text == selector }.first
        selected_field ? selected_field.value_detection.text : ""
      end
    end
  end
end
