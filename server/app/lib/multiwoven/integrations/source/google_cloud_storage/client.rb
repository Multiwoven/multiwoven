# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Source
      module GoogleCloudStorage
        class Client
          include Multiwoven::Integrations::Core

          def meta_data
            {
              data: {
                name: "GoogleCloudStorage",
                title: "Google Cloud Storage",
                connector_type: "source",
                category: "Data Lake",
                documentation_url: "https://docs.multiwoven.com",
                github_issue_label: "source-googlecloudstorage",
                icon: "icon.svg",
                license: "MIT",
                release_stage: "alpha",
                support_level: "community",
                tags: ["language:ruby", "multiwoven"]
              }
            }
          end

          def connector_spec
            {
              documentation_url: "https://docs.multiwoven.com/integrations/sources/googlecloudstorage",
              stream_type: "dynamic",
              connector_query_type: "raw_sql",
              connection_specification: {
                "$schema": "http://json-schema.org/draft-07/schema#",
                title: "Google Cloud Storage",
                type: "object",
                required: [
                  "project_id",
                  "client_email",
                  "private_key",
                  "bucket",
                  "file_type"
                ],
                additionalProperties: false,
                properties: {
                  project_id: {
                    type: "string",
                    title: "Project ID",
                    description: "Google Cloud Project ID",
                    order: 0
                  },
                  client_email: {
                    type: "string",
                    title: "Client Email",
                    description: "Service account client email",
                    order: 1
                  },
                  private_key: {
                    type: "string",
                    title: "Private Key",
                    description: "Service account private key",
                    multiwoven_secret: true,
                    order: 2
                  },
                  bucket: {
                    description: "Bucket Name",
                    type: "string",
                    title: "Bucket",
                    order: 3
                  },
                  path: {
                    description: "Path to csv or parquet files",
                    examples: [
                      "/path/to/files"
                    ],
                    type: "string",
                    title: "Path",
                    order: 4
                  },
                  file_type: {
                    description: "The type of file to read",
                    type: "string",
                    title: "File Type",
                    enum: [
                      "csv",
                      "parquet"
                    ],
                    order: 5
                  }
                }
              }
            }
          end

          # Helper method to format private key correctly
          def format_private_key(private_key)
            # Special case: Handle format where all newlines are represented by 'n'
            if private_key.include?("-----BEGIN PRIVATE KEY-----n")
              # Replace header and footer markers with proper format
              private_key = private_key.gsub("-----BEGIN PRIVATE KEY-----n", "-----BEGIN PRIVATE KEY-----\n")
              private_key = private_key.gsub("n-----END PRIVATE KEY-----", "\n-----END PRIVATE KEY-----")
              
              # Extract the key content (everything between the header and footer)
              header = "-----BEGIN PRIVATE KEY-----\n"
              footer = "\n-----END PRIVATE KEY-----"
              
              content_start = private_key.index(header) + header.length
              content_end = private_key.index(footer)
              
              if content_start && content_end && content_start < content_end
                # Extract the content
                content = private_key[content_start...content_end]
                
                # Replace all 'n' characters with newlines in the content
                content = content.gsub("n", "\n")
                
                # Format with proper line breaks after every 64 characters
                formatted_content = ""
                content.gsub(/\s+/, '').scan(/.{1,64}/).each do |line|
                  formatted_content += "#{line}\n"
                end
                
                # Reconstruct the key with proper format
                formatted_key = header + formatted_content + footer
                return formatted_key
              end
            end
            
            # Handle keys with escaped newlines (\n)
            if private_key.include?("\\n")
              private_key = private_key.gsub("\\n", "\n")
            end
            
            # If the key doesn't have proper headers, add them
            if !private_key.include?("-----BEGIN PRIVATE KEY-----")
              # Assume it's just the base64 content without headers
              content = private_key.gsub(/\s+/, '')
              
              formatted_key = "-----BEGIN PRIVATE KEY-----\n"
              content.scan(/.{1,64}/).each do |line|
                formatted_key += "#{line}\n"
              end
              formatted_key += "-----END PRIVATE KEY-----"
              
              return formatted_key
            end
            
            # If nothing else worked, return the original key
            private_key
          end
          
          def check_connection(connection_config)
            # Extract the connection parameters
            project_id = connection_config["project_id"]
            client_email = connection_config["client_email"]
            private_key = connection_config["private_key"]
            bucket = connection_config["bucket"]
            
            # Validate required parameters
            missing_params = []
            missing_params << "project_id" if project_id.nil? || project_id.strip.empty?
            missing_params << "client_email" if client_email.nil? || client_email.strip.empty?
            missing_params << "private_key" if private_key.nil? || private_key.strip.empty?
            missing_params << "bucket" if bucket.nil? || bucket.strip.empty?
            
            if missing_params.any?
              return {
                type: "CONNECTION_STATUS",
                connection_status: {
                  status: "failed",
                  message: "Missing required parameters: #{missing_params.join(', ')}"
                }
              }
            end

            begin
              require 'google/cloud/storage'
              
              # Format the private key properly
              formatted_key = format_private_key(private_key)
              
              # Create a Google Cloud Storage client
              storage = Google::Cloud::Storage.new(
                project_id: project_id,
                credentials: {
                  type: "service_account",
                  project_id: project_id,
                  private_key: formatted_key,
                  client_email: client_email
                }
              )
              
              # Check if the bucket exists
              bucket_obj = storage.bucket(bucket)
              
              if bucket_obj.nil? || !bucket_obj.exists?
                return {
                  type: "CONNECTION_STATUS",
                  connection_status: {
                    status: "failed",
                    message: "Bucket '#{bucket}' not found or you don't have access to it."
                  }
                }
              end
              
              # Connection successful
              {
                type: "CONNECTION_STATUS",
                connection_status: {
                  status: "succeeded",
                  message: "Successfully connected to Google Cloud Storage bucket: #{bucket}"
                }
              }
            rescue StandardError => e
              {
                type: "CONNECTION_STATUS",
                connection_status: {
                  status: "failed",
                  message: "Failed to connect to Google Cloud Storage: #{e.message}"
                }
              }
            end
          end

          def discover(connection_config)
            streams = [Multiwoven::Integrations::Protocol::Stream.new(name: "google_cloud_storage", action: StreamAction["fetch"], json_schema: {})]
            catalog = Catalog.new(streams: streams)
            catalog.to_multiwoven_message
          rescue StandardError => e
            handle_exception(e, { context: "GOOGLECLOUDSTORAGE:DISCOVER:EXCEPTION", type: "error" })
          end

          def read(sync_config)
            connection_config = sync_config.source.connection_specification
            project_id = connection_config["project_id"]
            client_email = connection_config["client_email"]
            private_key = connection_config["private_key"]
            bucket = connection_config["bucket"]
            path = connection_config["path"] || ""
            file_type = connection_config["file_type"]
            
            begin
              require 'google/cloud/storage'
              require 'csv'
              
              # Format the private key properly
              formatted_key = format_private_key(private_key)
              
              # Create a Google Cloud Storage client
              storage = Google::Cloud::Storage.new(
                project_id: project_id,
                credentials: {
                  type: "service_account",
                  project_id: project_id,
                  private_key: formatted_key,
                  client_email: client_email
                }
              )
              
              # Get the bucket
              bucket_obj = storage.bucket(bucket)
              
              # Prepare the path prefix
              prefix = path.start_with?("/") ? path[1..-1] : path
              
              # List files in the bucket with the given prefix
              files = bucket_obj.files(prefix: prefix)
              
              # Filter files by file type
              files = files.select { |file| file.name.end_with?(".#{file_type}") }
              
              # Process each file and collect records
              records = []
              
              files.each do |file|
                # Download the file content
                file_content = file.download
                
                # Process the file based on its type
                if file_type == "csv"
                  CSV.parse(file_content, headers: true).each do |row|
                    records << Multiwoven::Integrations::Protocol::Record.new(
                      data: row.to_h,
                      stream: "google_cloud_storage"
                    )
                  end
                elsif file_type == "parquet"
                  # We can't process parquet without specialized gems
                  # This is just a placeholder - actual implementation requires additional gems
                  Rails.logger.warn "Parquet file processing requires additional gems. Please use CSV format or install necessary parquet gems."
                end
              end
              
              records
            rescue StandardError => e
              handle_exception(e, {
                context: "GOOGLECLOUDSTORAGE:READ:EXCEPTION",
                type: "error",
                sync_id: sync_config.sync_id,
                sync_run_id: sync_config.sync_run_id
              })
            end
          end
        end
      end
    end
  end
end