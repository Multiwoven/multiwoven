# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Source::OneDrive::Client do
  let(:client) { described_class.new }
  let(:duckdb_conn) { instance_double(DuckDB::Connection) }
  let(:access_token) { "test-access-token" }
  let(:graph_auth_headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
  end

  let(:structured_config) do
    {
      data_type: "structured",
      user_name: "user@example.com",
      tenant_id: "tenant-id",
      client_id: "client-id",
      client_secret: "client-secret"
    }
  end

  let(:unstructured_config) do
    {
      data_type: "unstructured",
      user_name: "user@example.com",
      tenant_id: "tenant-id",
      client_id: "client-id",
      client_secret: "client-secret",
      share_url: "https://example.com/share-link"
    }
  end

  let(:sync_config) do
    {
      source: {
        name: "OneDrive",
        type: "source",
        connection_specification: structured_config
      },
      destination: {
        name: "Sample Destination Connector",
        type: "destination",
        connection_specification: {}
      },
      model: {
        name: "sales",
        query: "SELECT * FROM sales.csv",
        query_type: "raw_sql",
        primary_key: "id"
      },
      stream: {
        name: "sales.csv",
        json_schema: {}
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      sync_id: "sync-1",
      sync_run_id: nil
    }
  end

  let(:unstructured_sync_config) do
    {
      source: {
        name: "OneDrive",
        type: "source",
        connection_specification: unstructured_config
      },
      destination: sync_config[:destination],
      model: {
        name: "files",
        query: "list_files",
        query_type: "raw_sql",
        primary_key: "element_id"
      },
      stream: {
        name: "unstructured",
        json_schema: {}
      },
      sync_mode: "incremental",
      destination_sync_mode: "insert",
      sync_id: "sync-1",
      sync_run_id: "run-1"
    }
  end

  let(:list_items_response) do
    {
      "value" => [
        {
          "id" => "file-1",
          "name" => "report.pdf",
          "size" => 1024,
          "createdDateTime" => "2024-01-01T00:00:00Z",
          "lastModifiedDateTime" => "2024-01-02T00:00:00Z"
        },
        {
          "id" => "folder-1",
          "name" => "nested",
          "folder" => { "childCount" => 1 }
        }
      ]
    }
  end

  let(:spreadsheet_list_response) do
    {
      "value" => [
        { "id" => "csv-1", "name" => "sales.csv" },
        { "id" => "txt-1", "name" => "notes.txt" },
        { "id" => "xlsx-1", "name" => "report.xlsx" }
      ]
    }
  end

  let(:describe_results) do
    [
      { "column_name" => "id", "column_type" => "BIGINT" },
      { "column_name" => "amount", "column_type" => "DOUBLE" }
    ]
  end

  let(:share_url) { unstructured_config[:share_url] }
  let(:share_id) { client.send(:encode_sharing_url, share_url) }
  let(:share_item_url) do
    format(
      Multiwoven::Integrations::Core::Constants::MICROSOFT_GRAPH_SHARE_ITEM_URL,
      share_id: share_id
    )
  end
  let(:user_drive_url) do
    format(
      Multiwoven::Integrations::Core::Constants::MICROSOFT_GRAPH_USER_DRIVE_URL,
      user_name: structured_config[:user_name]
    )
  end

  before do
    allow(client).to receive(:create_connection)
    allow(client).to receive(:fetch_list_items).and_return(list_items_response)
  end

  describe "#check_connection" do
    context "with structured data" do
      before do
        allow(client).to receive(:create_connection).and_return(duckdb_conn)
        allow(client).to receive(:fetch_list_items).and_return(spreadsheet_list_response)
        allow(client).to receive(:describe_spreadsheet_file)
      end

      it "returns succeeded after DESCRIBE validates each spreadsheet" do
        expect(client).to receive(:describe_spreadsheet_file).with(duckdb_conn, hash_including("name" => "sales.csv")).ordered
        expect(client).to receive(:describe_spreadsheet_file).with(duckdb_conn, hash_including("name" => "report.xlsx")).ordered

        result = client.check_connection(structured_config).connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end

      it "returns failed when no spreadsheet files are found" do
        allow(client).to receive(:fetch_list_items).and_return({ "value" => [] })

        result = client.check_connection(structured_config).connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("No spreadsheet files found")
      end

      it "returns failed when a spreadsheet cannot be read" do
        allow(client).to receive(:describe_spreadsheet_file).and_raise(StandardError, "corrupt file")

        result = client.check_connection(structured_config).connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("corrupt file")
      end
    end

    context "with unstructured data" do
      it "returns succeeded after listing files" do
        result = client.check_connection(unstructured_config).connection_status

        expect(result.status).to eq("succeeded")
        expect(result.message).to be_nil
      end

      it "returns failed when listing files fails" do
        allow(client).to receive(:fetch_list_items).and_raise(StandardError, "listing files failed")

        result = client.check_connection(unstructured_config).connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("listing files failed")
      end
    end

    context "when create_connection raises" do
      it "returns failed with the error message" do
        allow(client).to receive(:create_connection).and_raise(StandardError, "Connection failed")

        result = client.check_connection(structured_config).connection_status

        expect(result.status).to eq("failed")
        expect(result.message).to include("Connection failed")
      end
    end
  end

  describe "#discover" do
    context "with unstructured data" do
      it "returns a catalog with a single unstructured stream" do
        message = client.discover(unstructured_config)

        expect(message.catalog).to be_a(Multiwoven::Integrations::Protocol::Catalog)
        expect(message.catalog.streams).to be_an(Array)
        expect(message.catalog.streams.first).to be_a(Multiwoven::Integrations::Protocol::Stream)
        expect(message.catalog.streams.first.name).to eq("unstructured")
      end
    end

    context "with structured data" do
      before do
        allow(client).to receive(:create_connection).and_return(duckdb_conn)
        allow(client).to receive(:fetch_list_items).and_return(spreadsheet_list_response)
        allow(client).to receive(:download_file_to_local).and_return("/tmp/file.csv")
        allow(client).to receive(:read_local_file).and_return("read_csv_auto('/tmp/file.csv')")
        allow(client).to receive(:get_results).and_return(describe_results)
      end

      it "returns a stream per spreadsheet using the full file name" do
        message = client.discover(structured_config)
        stream_names = message.catalog.streams.map(&:name)

        expect(stream_names).to contain_exactly("sales.csv", "report.xlsx")
      end

      it "builds all-string json_schema from DuckDB DESCRIBE results" do
        message = client.discover(structured_config)
        schema = message.catalog.streams.first.json_schema

        expect(schema["properties"].keys).to contain_exactly("id", "amount")
        expect(schema["properties"]["id"]["type"]).to eq("string")
        expect(schema["properties"]["amount"]["type"]).to eq("string")
      end

      it "handles exceptions when no spreadsheet files are found" do
        allow(client).to receive(:fetch_list_items).and_return({ "value" => [] })

        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError),
          { context: "ONE_DRIVE:DISCOVER:EXCEPTION", type: "error" }
        )

        client.discover(structured_config)
      end

      it "removes ephemeral downloads after each DESCRIBE" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("FILE_DOWNLOAD_PATH").and_return(nil)

        temp_dir = Dir.mktmpdir("one_drive_spec")
        client.instance_variable_set(:@temp_download_dir, temp_dir)
        local_path = File.join(temp_dir, "sales.csv")
        allow(client).to receive(:download_file_to_local).and_return(local_path)
        File.write(local_path, "col1\n1")

        client.send(:describe_spreadsheet_file, duckdb_conn, spreadsheet_list_response["value"].first)

        expect(File).not_to exist(local_path)
      ensure
        FileUtils.remove_entry(temp_dir) if temp_dir && Dir.exist?(temp_dir)
      end
    end

    context "when discovery fails" do
      it "handles exceptions" do
        allow(unstructured_config).to receive(:with_indifferent_access).and_raise(StandardError, "Discovery failed")

        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError),
          { context: "ONE_DRIVE:DISCOVER:EXCEPTION", type: "error" }
        )

        client.discover(unstructured_config)
      end
    end
  end

  describe "#read" do
    context "with structured data" do
      before do
        allow(client).to receive(:create_connection).and_return(duckdb_conn)
        allow(client).to receive(:download_file_to_local).and_return("/tmp/sales.csv")
        allow(client).to receive(:read_local_file).and_return("read_csv_auto('/tmp/sales.csv')")
        allow(client).to receive(:get_results).and_return([{ "id" => "1", "amount" => "100" }])
      end

      it "reads records successfully" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        records = client.read(s_config)

        expect(records).to be_an(Array)
        expect(records).not_to be_empty
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data).to eq({ "id" => "1", "amount" => "100" })
      end

      it "reads records with batched query" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.limit = 100
        s_config.offset = 1

        expect(client).to receive(:get_results).with(
          duckdb_conn,
          a_string_including("LIMIT 100 OFFSET 1")
        ).and_return([{ "id" => "1" }])

        records = client.read(s_config)

        expect(records).to be_an(Array)
        expect(records.first.record.data).to eq({ "id" => "1" })
      end

      it "handles read failures" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(sync_config.to_json)
        s_config.sync_run_id = "run-2"
        allow(client).to receive(:create_connection).and_raise(StandardError, "test error")

        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError),
          {
            context: "ONE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: "sync-1",
            sync_run_id: "run-2"
          }
        )

        client.read(s_config)
      end

      describe "#extract_file_name_from_query" do
        it "extracts backtick-quoted file names" do
          expect(client.send(:extract_file_name_from_query, "SELECT * FROM `sales.csv`")).to eq("sales.csv")
        end

        it "extracts double-quoted file names" do
          expect(client.send(:extract_file_name_from_query, 'SELECT * FROM "report.xlsx"')).to eq("report.xlsx")
        end

        it "extracts single-quoted file names" do
          expect(client.send(:extract_file_name_from_query, "SELECT * FROM 'data.csv'")).to eq("data.csv")
        end

        it "extracts bare file names" do
          expect(client.send(:extract_file_name_from_query, "SELECT * FROM sales.csv")).to eq("sales.csv")
        end

        it "extracts file names before a terminating semicolon" do
          expect(client.send(:extract_file_name_from_query, "SELECT * FROM sales.csv;")).to eq("sales.csv")
        end

        it "raises when the file name cannot be extracted" do
          expect do
            client.send(:extract_file_name_from_query, "SELECT 1")
          end.to raise_error(ArgumentError, "Could not extract file name from query")
        end
      end
    end

    context "with unstructured data" do
      it "returns records for list_files" do
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        records = client.read(s_config)

        expect(records).to be_an(Array)
        expect(records.first).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(records.first.record.data[:element_id]).to eq("file-1")
        expect(records.first.record.data[:file_name]).to eq("report.pdf")
        expect(records.first.record.data[:file_path]).to eq("report.pdf")
        expect(records.first.record.data[:file_type]).to eq("pdf")
      end

      it "returns records for download_file" do
        unstructured_sync_config[:model][:query] = "download_file report.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        allow(client).to receive(:download_file_to_local).and_return("/tmp/report.pdf")

        records = client.read(s_config)

        expect(records).to be_an(Array)
        expect(records.first.record.data[:local_path]).to eq("/tmp/report.pdf")
        expect(records.first.record.data[:file_name]).to eq("report.pdf")
        expect(records.first.record.data[:file_path]).to eq("report.pdf")
      end

      it "returns records for download_file with quoted file names" do
        unstructured_sync_config[:model][:query] = 'download_file "report.pdf"'
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        allow(client).to receive(:download_file_to_local).and_return("/tmp/report.pdf")

        records = client.read(s_config)

        expect(records.first.record.data[:file_name]).to eq("report.pdf")
      end

      it "handles a missing file" do
        unstructured_sync_config[:model][:query] = "download_file missing.pdf"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        s_config.sync_run_id = "run-1"

        expect(client).to receive(:handle_exception).with(
          an_instance_of(StandardError),
          {
            context: "ONE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: "sync-1",
            sync_run_id: "run-1"
          }
        )

        client.read(s_config)
      end

      it "handles an invalid command" do
        unstructured_sync_config[:model][:query] = "invalid_command"
        s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
        s_config.sync_run_id = "run-1"

        expect(client).to receive(:handle_exception).with(
          an_instance_of(ArgumentError),
          {
            context: "ONE_DRIVE:READ:EXCEPTION",
            type: "error",
            sync_id: "sync-1",
            sync_run_id: "run-1"
          }
        )

        client.read(s_config)
      end

      context "when FILE_DOWNLOAD_PATH is set" do
        before do
          allow(ENV).to receive(:[]).with("FILE_DOWNLOAD_PATH").and_return("/custom/download/path")
        end

        it "returns the configured download path" do
          unstructured_sync_config[:model][:query] = "download_file report.pdf"
          s_config = Multiwoven::Integrations::Protocol::SyncConfig.from_json(unstructured_sync_config.to_json)
          allow(client).to receive(:download_file_to_local).and_return("/custom/download/path/syncs/sync-1/report.pdf")

          records = client.read(s_config)

          expect(records).to be_an(Array)
          expect(records.first.record.data[:local_path]).to eq("/custom/download/path/syncs/sync-1/report.pdf")
        end
      end
    end
  end

  describe "connection and share URL resolution" do
    before do
      allow(client).to receive(:create_connection).and_call_original
      allow(client).to receive(:refresh_access_token).and_return(access_token)
      allow(DuckDB::Database).to receive(:open).and_return(
        instance_double(DuckDB::Database, connect: duckdb_conn)
      )
      allow(duckdb_conn).to receive(:execute)
    end

    describe "#create_connection" do
      context "via user drive" do
        it "resolves drive_id and returns a DuckDB connection" do
          drive_response = instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: { "id" => "drive-from-user" }.to_json
          )

          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            user_drive_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).and_return(drive_response)

          connection = client.send(:create_connection, structured_config)

          expect(connection).to eq(duckdb_conn)
          expect(client.instance_variable_get(:@drive_id)).to eq("drive-from-user")
        end
      end

      context "via share URL" do
        let(:share_response) do
          instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: {
              "id" => "shared-folder-item",
              "parentReference" => { "driveId" => "shared-drive-id" },
              "folder" => { "childCount" => 2 }
            }.to_json
          )
        end

        it "resolves drive_id and skips DuckDB for unstructured data" do
          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            share_item_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).and_return(share_response)

          connection = client.send(:create_connection, unstructured_config)

          expect(connection).to be_nil
          expect(client.instance_variable_get(:@drive_id)).to eq("shared-drive-id")
        end
      end
    end

    describe "#encode_sharing_url" do
      it "encodes a sharing URL into the Microsoft Graph share id format" do
        url = "https://contoso.sharepoint.com/:f:/r/sites/Test/Shared%20Documents"
        expected = "u!#{Base64.strict_encode64(url).tr("+/", "-_").delete("=")}"

        expect(client.send(:encode_sharing_url, url)).to eq(expected)
      end
    end

    describe "#shared_folder_reference" do
      before do
        client.instance_variable_set(:@share_url, share_url)
        client.instance_variable_set(:@access_token, access_token)
      end

      it "resolves drive and item ids and memoizes the result" do
        share_response = instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: {
            "id" => "shared-item-id",
            "parentReference" => { "driveId" => "shared-drive-id" },
            "file" => { "mimeType" => "application/pdf" }
          }.to_json
        )

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          share_item_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: graph_auth_headers
        ).once.and_return(share_response)

        first_reference = client.send(:shared_folder_reference)
        second_reference = client.send(:shared_folder_reference)

        expect(first_reference).to eq(
          drive_id: "shared-drive-id",
          item_id: "shared-item-id",
          is_file: true
        )
        expect(second_reference).to eq(first_reference)
      end
    end
  end

  describe "OAuth token handling" do
    let(:token_url) do
      format(
        Multiwoven::Integrations::Core::Constants::MICROSOFT_GRAPH_TOKEN_URL,
        tenant_id: structured_config[:tenant_id]
      )
    end
    let(:expired_token) { "expired-token" }
    let(:fresh_token) { "fresh-token" }
    let(:expired_response_body) do
      {
        "error" => {
          "code" => "InvalidAuthenticationToken",
          "message" => "Lifetime validation failed, the token is expired."
        }
      }.to_json
    end
    let(:expired_headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{expired_token}",
        "Content-Type" => "application/json"
      }
    end
    let(:fresh_headers) do
      {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{fresh_token}",
        "Content-Type" => "application/json"
      }
    end

    before do
      client.instance_variable_set(:@tenant_id, structured_config[:tenant_id])
      client.instance_variable_set(:@client_id, structured_config[:client_id])
      client.instance_variable_set(:@client_secret, structured_config[:client_secret])
    end

    describe "#fetch_access_token" do
      it "requests a client-credentials token with form-urlencoded payload" do
        token_response = instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: { "access_token" => "new-access-token" }.to_json
        )
        expected_payload = URI.encode_www_form(
          client_id: structured_config[:client_id],
          client_secret: structured_config[:client_secret],
          scope: Multiwoven::Integrations::Core::Constants::MICROSOFT_GRAPH_SCOPE,
          grant_type: "client_credentials"
        )

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          token_url,
          Multiwoven::Integrations::Core::Constants::HTTP_POST,
          payload: satisfy { |payload| payload.to_json == expected_payload },
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        ).and_return(token_response)

        expect(client.send(:fetch_access_token)).to eq("new-access-token")
      end

      it "raises when the token endpoint returns an error" do
        error_response = instance_double(
          Net::HTTPUnauthorized,
          code: "401",
          body: {
            "error" => "invalid_client",
            "error_description" => "Invalid client secret"
          }.to_json
        )

        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).and_return(error_response)

        expect { client.send(:fetch_access_token) }.to raise_error(StandardError, /invalid_client/)
      end
    end

    describe "#form_urlencoded_payload" do
      it "serializes fields as application/x-www-form-urlencoded via #to_json" do
        payload = client.send(
          :form_urlencoded_payload,
          client_id: "client-id",
          client_secret: "client-secret",
          scope: "https://graph.microsoft.com/.default",
          grant_type: "client_credentials"
        )

        expect(payload.to_json).to eq(
          "client_id=client-id&client_secret=client-secret&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&grant_type=client_credentials"
        )
      end
    end

    describe "expired token retry" do
      let(:url) { "https://graph.microsoft.com/v1.0/test" }

      before do
        client.instance_variable_set(:@access_token, expired_token)
      end

      it "refreshes the token and retries microsoft_graph_request once" do
        expired_response = instance_double(Net::HTTPUnauthorized, code: "401", body: expired_response_body)
        success_response = instance_double(Net::HTTPSuccess, code: "200", body: { "value" => [] }.to_json)

        expect(client).to receive(:refresh_access_token).once do
          client.instance_variable_set(:@access_token, fresh_token)
          fresh_token
        end

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: expired_headers
        ).ordered.and_return(expired_response)

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: fresh_headers
        ).ordered.and_return(success_response)

        expect(client.send(:microsoft_graph_request, url).body).to eq(success_response.body)
      end

      it "retries paginated listing when the first page returns an expired token" do
        allow(client).to receive(:fetch_list_items).and_call_original
        client.instance_variable_set(:@drive_id, "drive-1")
        client.instance_variable_set(:@share_url, nil)
        client.instance_variable_set(:@data_type, "structured")

        first_page_url = "https://graph.microsoft.com/v1.0/drives/drive-1/root/children"
        expired_response = instance_double(Net::HTTPUnauthorized, code: "401", body: expired_response_body)
        success_response = instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: { "value" => [{ "id" => "csv-1", "name" => "sales.csv" }] }.to_json
        )

        expect(client).to receive(:refresh_access_token).once do
          client.instance_variable_set(:@access_token, fresh_token)
          fresh_token
        end

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          first_page_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: expired_headers
        ).ordered.and_return(expired_response)

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          first_page_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: fresh_headers
        ).ordered.and_return(success_response)

        result = client.send(:fetch_list_items)

        expect(result["value"].map { |item| item["name"] }).to eq(["sales.csv"])
      end
    end
  end

  describe "Graph file operations" do
    before do
      client.instance_variable_set(:@access_token, access_token)
    end

    describe "#fetch_file_content" do
      let(:content_url) { "https://graph.microsoft.com/v1.0/drives/drive-1/items/item-1/content" }
      let(:redirect_url) { "https://cdn.example.com/download/file" }

      it "follows a 302 redirect to download file content" do
        redirect_response = Net::HTTPFound.new("1.1", "302", "Found")
        redirect_response["location"] = redirect_url
        file_response = instance_double(Net::HTTPSuccess, code: "200", body: "file-binary-content")

        allow(client).to receive(:microsoft_graph_request).with(content_url).and_return(redirect_response)
        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          redirect_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET
        ).and_return(file_response)

        expect(client.send(:fetch_file_content, content_url).body).to eq("file-binary-content")
      end

      it "returns the original response when no redirect is issued" do
        success_response = instance_double(Net::HTTPSuccess, code: "200", body: "inline-content")

        allow(client).to receive(:microsoft_graph_request).with(content_url).and_return(success_response)
        expect(Multiwoven::Integrations::Core::HttpClient).not_to receive(:request)

        expect(client.send(:fetch_file_content, content_url).body).to eq("inline-content")
      end
    end

    describe "#fetch_list_items" do
      before do
        allow(client).to receive(:fetch_list_items).and_call_original
        client.instance_variable_set(:@drive_id, "drive-1")
        client.instance_variable_set(:@share_url, nil)
        client.instance_variable_set(:@data_type, "structured")
      end

      it "follows @odata.nextLink and merges all pages" do
        first_page_url = "https://graph.microsoft.com/v1.0/drives/drive-1/root/children"
        next_page_url = "https://graph.microsoft.com/v1.0/drives/drive-1/root/children?$skiptoken=abc"

        first_response = instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: {
            "value" => [{ "id" => "csv-1", "name" => "sales.csv" }],
            "@odata.nextLink" => next_page_url
          }.to_json
        )
        second_response = instance_double(
          Net::HTTPSuccess,
          code: "200",
          body: {
            "value" => [{ "id" => "xlsx-1", "name" => "report.xlsx" }]
          }.to_json
        )

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          first_page_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: graph_auth_headers
        ).and_return(first_response)

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          next_page_url,
          Multiwoven::Integrations::Core::Constants::HTTP_GET,
          headers: graph_auth_headers
        ).and_return(second_response)

        result = client.send(:fetch_list_items)

        expect(result["value"].map { |item| item["name"] }).to eq(%w[sales.csv report.xlsx])
      end

      context "with a configured file_name" do
        let(:file_url) { "https://graph.microsoft.com/v1.0/drives/drive-1/root:/report.pdf" }
        let(:file_response) do
          instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: {
              "id" => "file-1",
              "name" => "report.pdf",
              "size" => 1024,
              "createdDateTime" => "2024-01-01T00:00:00Z",
              "lastModifiedDateTime" => "2024-01-02T00:00:00Z"
            }.to_json
          )
        end

        before do
          client.instance_variable_set(:@data_type, "unstructured")
          client.instance_variable_set(:@file_name, "report.pdf")
        end

        it "fetches only the configured file" do
          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            file_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).and_return(file_response)

          result = client.send(:fetch_list_items)

          expect(result["value"].map { |item| item["name"] }).to eq(["report.pdf"])
        end
      end

      context "with a share URL" do
        let(:children_url) { "#{share_item_url}/children" }

        before do
          client.instance_variable_set(:@share_url, share_url)
          client.instance_variable_set(:@data_type, "unstructured")
        end

        it "lists children when the shared link points to a folder" do
          folder_metadata_response = instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: {
              "id" => "shared-folder-item",
              "parentReference" => { "driveId" => "shared-drive-id" },
              "folder" => { "childCount" => 1 }
            }.to_json
          )
          children_response = instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: { "value" => [{ "id" => "file-1", "name" => "report.pdf" }] }.to_json
          )

          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            share_item_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).ordered.and_return(folder_metadata_response)

          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            children_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).ordered.and_return(children_response)

          result = client.send(:fetch_list_items)

          expect(result["value"].map { |item| item["name"] }).to eq(["report.pdf"])
        end

        it "returns shared file metadata when the shared link points to a file" do
          file_metadata_response = instance_double(
            Net::HTTPSuccess,
            code: "200",
            body: {
              "id" => "shared-file-item",
              "name" => "shared-report.pdf",
              "parentReference" => { "driveId" => "shared-drive-id" },
              "file" => { "mimeType" => "application/pdf" }
            }.to_json
          )

          expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
            share_item_url,
            Multiwoven::Integrations::Core::Constants::HTTP_GET,
            headers: graph_auth_headers
          ).twice.and_return(file_metadata_response)

          result = client.send(:fetch_list_items)

          expect(result["value"].map { |item| item["name"] }).to eq(["shared-report.pdf"])
        end
      end
    end
  end

  describe "connector interface" do
    it "exposes meta_data with the connector module name" do
      meta_name = client.class.to_s.split("::")[-2]
      expect(client.send(:meta_data)[:data][:name]).to eq(meta_name)
    end

    it "defines private #create_connection and #query methods" do
      private_methods = described_class.private_instance_methods
      expect(private_methods).to include(:create_connection, :query)
    end
  end
end
