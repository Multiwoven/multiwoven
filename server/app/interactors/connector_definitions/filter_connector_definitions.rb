# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectorDefinitions
    include Interactor

    def call
      context.connectors = Multiwoven::Integrations::Service.connectors.with_indifferent_access

      # Add Google Cloud Storage connector
      add_google_cloud_storage_connector
      filter_connectors_by_category if context.category
      context.connectors = context.connectors[context.type] if context.type
    end

    private

    def filter_connectors_by_category
      categories = case context.category
                   when "data"
                     Connector::DATA_CATEGORIES
                   when "ai_ml"
                     Connector::AI_ML_CATEGORIES
                   else
                     [context.category]
                   end
      context.connectors[:source] = filter_by_category(context.connectors[:source], categories)
      context.connectors[:destination] = filter_by_category(context.connectors[:destination], categories)
    end

    def filter_by_category(connectors, categories)
      connectors.select { |connector| categories.include?(connector[:category]) }
    end

    def add_google_cloud_storage_connector
      # Check if Google Cloud Storage is already in the list
      return if context.connectors[:source].any? { |c| c[:name] == "GoogleCloudStorage" }

      # Create Google Cloud Storage connector metadata
      gcs_connector = {
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
        tags: ["language:ruby", "multiwoven"],
        connector_spec: {
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
      }

      # Add Google Cloud Storage connector to the list of source connectors
      context.connectors[:source] << gcs_connector
    end
  end
end
