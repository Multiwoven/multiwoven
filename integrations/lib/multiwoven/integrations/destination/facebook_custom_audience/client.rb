# frozen_string_literal: true

module Multiwoven::Integrations::Destination
  module FacebookCustomAudience
    include Multiwoven::Integrations::Core
    class Client < DestinationConnector
      prepend Multiwoven::Integrations::Core::RateLimiter
      MAX_CHUNK_SIZE = 10_000
      def check_connection(connection_config)
        connection_config = connection_config.with_indifferent_access
        access_token = connection_config[:access_token]
        ad_account_id = connection_config[:ad_account_id]
        
        begin
          response = Multiwoven::Integrations::Core::HttpClient.request(
            FACEBOOK_AUDIENCE_GET_ALL_ACCOUNTS,
            HTTP_GET,
            headers: auth_headers(access_token)
          )
          
          # Check if response is a Net::HTTPResponse object
          if response.is_a?(Net::HTTPResponse)
            if response.is_a?(Net::HTTPSuccess)
              ad_account_exists?(response, ad_account_id)
              return ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
            else
              error_message = "Facebook API error: #{response.code} - #{response.message}"
              if response.body
                begin
                  error_details = JSON.parse(response.body)
                  if error_details['error'] && error_details['error']['message']
                    error_message += ". #{error_details['error']['message']}"
                  end
                rescue JSON::ParserError
                  # If we can't parse the body, just use the status code message
                end
              end
              return ConnectionStatus.new(
                status: ConnectionStatusType["failed"], 
                message: error_message
              ).to_multiwoven_message
            end
          else
            # Handle case where response is not a Net::HTTPResponse
            if success?(response)
              ad_account_exists?(response, ad_account_id)
              return ConnectionStatus.new(status: ConnectionStatusType["succeeded"]).to_multiwoven_message
            else
              return ConnectionStatus.new(
                status: ConnectionStatusType["failed"], 
                message: "Failed to connect to Facebook API"
              ).to_multiwoven_message
            end
          end
        rescue StandardError => e
          return ConnectionStatus.new(
            status: ConnectionStatusType["failed"], 
            message: "Error connecting to Facebook: #{e.message}"
          ).to_multiwoven_message
        end
      end

      def discover(_connection_config = nil)
        catalog_json = read_json(CATALOG_SPEC_PATH)
        catalog = build_catalog(catalog_json)
        catalog.to_multiwoven_message
      rescue StandardError => e
        handle_exception(e, {
                           context: "FACEBOOK AUDIENCE:DISCOVER:EXCEPTION",
                           type: "error"
                         })
      end

      def write(sync_config, records, _action = "destination_insert")
        connection_config = sync_config.destination.connection_specification.with_indifferent_access
        access_token = connection_config[:access_token]
        url = generate_url(sync_config, connection_config)
        write_success = 0
        write_failure = 0
        error_details = []
        
        records.each_slice(MAX_CHUNK_SIZE) do |chunk|
          payload = create_payload(chunk, sync_config.stream.json_schema.with_indifferent_access)
          response = Multiwoven::Integrations::Core::HttpClient.request(
            url,
            sync_config.stream.request_method,
            payload: payload,
            headers: auth_headers(access_token)
          )
          if success?(response)
            write_success += chunk.size
          else
            write_failure += chunk.size
            # Log the error response from Facebook
            error_message = extract_error_message(response)
            Rails.logger.error("FB_AUDIENCE_ERROR: API error for #{chunk.size} records: #{error_message}")
            
            # Store error details for tracking
            error_details << {
              error_type: 'api_error',
              error_message: error_message,
              record_count: chunk.size
            }
          end
        rescue StandardError => e
          write_failure += chunk.size
          error_message = "#{e.class}: #{e.message}"
          
          # Log the exception
          Rails.logger.error("FB_AUDIENCE_ERROR: Exception during processing: #{error_message}")
          
          handle_exception(e, {
            context: "FACEBOOK:RECORD:WRITE:EXCEPTION",
            type: "error",
            sync_id: sync_config.sync_id,
            sync_run_id: sync_config.sync_run_id
          })
          
          # Store error details for tracking
          error_details << {
            error_type: 'exception',
            error_message: error_message,
            record_count: chunk.size
          }
        end

        # Create tracking message with error logs if there were failures
        tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: write_success,
          failed: write_failure
        )
        
        # Add error logs if available
        if error_details.any?
          error_log = { errors: error_details, summary: "#{write_failure} records failed during sync" }
          log_message = Multiwoven::Integrations::Protocol::LogMessage.new(
            level: "ERROR",
            message: error_log.to_json
          )
          tracker.logs = [log_message]
        end
        
        tracker.to_multiwoven_message
      rescue StandardError => e
        error_message = "#{e.class}: #{e.message}"
        Rails.logger.error("FB_AUDIENCE_ERROR: Fatal error: #{error_message}")
        
        handle_exception(e, {
          context: "FACEBOOK:RECORD:WRITE:EXCEPTION",
          type: "error",
          sync_id: sync_config.sync_id,
          sync_run_id: sync_config.sync_run_id
        })
      end

      private

      def generate_url(sync_config, connection_config)
        sync_config.stream.url.gsub("{audience_id}", connection_config[:audience_id])
      end

      def create_payload(records, json_schema)
        schema, data = extract_schema_and_data(records, json_schema)
        {
          "payload" => {
            "schema" => schema,
            "data" => data
          }
        }
      end
      

      
      def extract_error_message(response)
        if response.is_a?(Net::HTTPResponse)
          if response.body
            begin
              error_details = JSON.parse(response.body)
              if error_details['error'] && error_details['error']['message']
                return "#{response.code} - #{error_details['error']['message']}"
              end
            rescue JSON::ParserError
              # If we can't parse the body
            end
          end
          return "#{response.code} - #{response.message}"
        else
          # For non-Net::HTTPResponse objects
          return "Unknown error: #{response.inspect}"
        end
      end

      def extract_schema_and_data(records, json_schema)
        schema_properties = json_schema[:properties]
        schema = records.first.keys.map(&:to_s).map(&:upcase)
        data = []
        skipped_rows = []
        required_keys = schema_properties.select { |_k, v| v["x-hashRequired"] }.keys
        records.each_with_index do |record, idx|
          encrypted_data_array = []
          record_hash = record.with_indifferent_access
          missing_fields = required_keys.select { |rk| record_hash[rk.downcase].blank? && record_hash[rk].blank? }
          if missing_fields.any?
            reason = "Missing required fields: #{missing_fields.join(", ")}"
            skipped_rows << { row_index: idx, row: record, reason: reason }
            Rails.logger.info("FB_AUDIENCE_SKIPPED_ROW: index=#{idx}, reason=#{reason}, row=#{record}")
          end
          record_hash.each do |key, value|
            schema_key = key.upcase
            encrypted_value = schema_properties[schema_key] && schema_properties[schema_key]["x-hashRequired"] ? Digest::SHA256.hexdigest(value.to_s) : value
            encrypted_data_array << encrypted_value
          end
          data << encrypted_data_array
        end
        if skipped_rows.any?
          Rails.logger.info("FB_AUDIENCE_SKIPPED_SUMMARY: #{skipped_rows.size} rows with missing required fields. Details: #{skipped_rows.map { |r| { index: r[:row_index], reason: r[:reason] } }.to_json}")
        end
        [schema, data]
      end

      def ad_account_exists?(response, ad_account_id)
        data = extract_data(response)
        
        # Try both with and without the 'act_' prefix
        account_found = data.any? do |ad_account| 
          ad_account["id"] == "act_#{ad_account_id}" || 
          ad_account["id"] == ad_account_id ||
          ad_account["id"].gsub('act_', '') == ad_account_id
        end
        
        return if account_found

        raise ArgumentError, "Ad account not found in business account. Available accounts: #{data.map { |a| a['id'] }.join(', ')}"
      end

      def extract_data(response)
        response_body = response.body
        JSON.parse(response_body)["data"] if response_body
      end
    end
  end
end
