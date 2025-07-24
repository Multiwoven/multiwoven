# frozen_string_literal: true

module Multiwoven::Integrations::Source
  module Firecrawl
    include Multiwoven::Integrations::Core
    class Client < SourceConnector
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        create_connection(connection_config)
        request = crawl_activity
        if success?(request)
          success_status
        else
          failure_status(nil)
        end
      rescue StandardError => e
        handle_exception(e, { context: "FIRECRAWL:CHECK_CONNECTION:EXCEPTION", type: "error" })
        failure_status(e)
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, { context: "FIRECRAWL:DISCOVER:EXCEPTION", type: "error" })
      end

      def read(sync_config)
        connection_config = sync_config.source.connection_specification
        connection_config = connection_config.with_indifferent_access
        url = create_connection(connection_config)
        query(url, nil, nil)
      rescue StandardError => e
        handle_exception(e, {
                           context: "FIRECRAWL:READ:EXCEPTION",
                           type: "error",
                           sync_id: sync_config.sync_id,
                           sync_run_id: sync_config.sync_run_id
                         })
      end

      private

      def create_connection(connection_config)
        @base_url = connection_config[:base_url]
        @api_key = connection_config[:api_key]
        @config = if connection_config[:config].present?
                    connection_config[:config].transform_values do |value|
                      JSON.parse(value)
                    rescue JSON::ParserError
                      value
                    end
                  else
                    {}
                  end
        @config[:url] ||= connection_config[:base_url]
        FIRECRAWL_CRAWL_URL
      end

      def query(url, _query, limit = 1)
        if limit.present?
          if @config["includePaths"]&.any?
            path = @config["includePaths"].first
            @config["url"] = URI.join(@config["url"], path).to_s
          end
          @config.delete("includePaths")
          @config[:limit] = limit
        end
        request = execute_crawl(url)
        request = JSON.parse(request.body)
        crawl_url = get_request_url(request)
        response = get_crawl_result(crawl_url)
        response["data"].map do |row|
          metadata_json = row["metadata"].to_json if row["metadata"]
          metadata_url = row["metadata"]["url"]
          data = {
            "metadata": metadata_json,
            "markdown": row["markdown"],
            "url": metadata_url
          }
          RecordMessage.new(data: data, emitted_at: Time.now.to_i).to_multiwoven_message
        end
      end

      def execute_crawl(url)
        send_request(
          url: url,
          http_method: HTTP_POST,
          payload: JSON.parse(@config.to_json),
          headers: auth_headers(@api_key),
          config: {}
        )
      end

      def crawl_activity
        send_request(
          url: FIRECRAWL_CRAWL_ACTIVE_URL,
          http_method: HTTP_GET,
          payload: {},
          headers: auth_headers(@api_key),
          config: {}
        )
      end

      # This is to make sure the /crawl/{id} was returned in request.
      # If not use /crawl/active to retrieve it.
      def get_request_url(request)
        if request["url"].blank?
          if request["error"].present?
            time = request["error"][/retry after (\d+)s/, 1].to_i
            sleep(time)
            execute_crawl(FIRECRAWL_CRAWL_URL)
          end
          active = crawl_activity
          crawl_active = JSON.parse(active.body)

          raise "Missing crawl result URL and no active crawl ID available." unless crawl_active["crawls"][-1]["id"].present?

          crawl_id = crawl_active["crawls"][-1]["id"]
          build_url(FIRECRAWL_GET_CRAWL_URL, crawl_id.to_s)
        else
          request["url"]
        end
      end

      # Crawl job needs time to finish task. This method will check if the job is complete.
      # If not sleep for 5 seconds and check again.
      def get_crawl_result(url)
        loop do
          response = send_request(
            url: url,
            http_method: HTTP_GET,
            payload: {},
            headers: auth_headers(@api_key),
            config: {}
          )
          response = JSON.parse(response.body)
          return response if response["status"] != "scraping"

          sleep(FIRECRAWL_REQUEST_RATE_LIMIT)
        end
      end

      def build_url(url, id)
        format(url, id: id)
      end
    end
  end
end
