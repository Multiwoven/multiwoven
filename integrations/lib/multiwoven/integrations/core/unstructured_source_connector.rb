# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class UnstructuredSourceConnector < SourceConnector
      UNSTRUCTURED_SCHEMA = {
        type: "object",
        properties: {
          element_id: { type: "string" },
          text: { type: "string" },
          created_date: { type: "string" },
          modified_date: { type: "string" },
          filename: { type: "string" },
          filetype: { type: "string" }
        },
        required: %w[
          element_id
          text
          created_date
          modified_date
          filename
          filetype
        ]
      }.freeze

      UNSTRUCTURED_STREAM_CONFIG = {
        supported_sync_modes: ["incremental"],
        source_defined_cursor: true,
        default_cursor_field: ["modified_date"],
        source_defined_primary_key: [["element_id"]]
      }.freeze

      # Commands for unstructured data operations
      UNSTRUCTURED = "unstructured"
      LIST_FILES_CMD = "list_files"
      DOWNLOAD_FILE_CMD = "download_file"

      def unstructured_data?(connection_config)
        connection_config["data_type"] == UNSTRUCTURED
      end

      def create_unstructured_stream
        Multiwoven::Integrations::Protocol::Stream.new(
          name: UNSTRUCTURED,
          action: StreamAction["fetch"],
          json_schema: UNSTRUCTURED_SCHEMA,
          **UNSTRUCTURED_STREAM_CONFIG
        )
      end
    end
  end
end
