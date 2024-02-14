# frozen_string_literal: true

module Multiwoven
  module Integrations::Protocol
    module Types
      include Dry.Types()
    end

    SyncMode = Types::String.enum("full_refresh", "incremental")
    SyncStatus = Types::String.enum("started", "running", "complete", "incomplete")
    DestinationSyncMode = Types::String.enum("insert", "upsert")
    ConnectorType = Types::String.enum("source", "destination")
    ModelQueryType = Types::String.enum("raw_sql", "dbt")
    ConnectionStatusType = Types::String.enum("succeeded", "failed")
    StreamType = Types::String.enum("static", "dynamic")
    StreamAction = Types::String.enum("fetch", "create", "update", "delete")
    MultiwovenMessageType = Types::String.enum(
      "record", "log", "connector_spec",
      "connection_status", "catalog", "control",
      "tracking"
    )
    ControlMessageType = Types::String.enum(
      "rate_limit", "connection_config"
    )
    LogLevel = Types::String.enum("fatal", "error", "warn", "info", "debug", "trace")

    class ProtocolModel < Dry::Struct
      extend Multiwoven::Integrations::Core::Utils
      class << self
        def from_json(json_string)
          data = JSON.parse(json_string)
          new(keys_to_symbols(data))
        end
      end
    end

    class ConnectionStatus < ProtocolModel
      attribute :status, ConnectionStatusType
      attribute? :message, Types::String.optional

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["connection_status"],
          connection_status: self
        )
      end
    end

    class ConnectorSpecification < ProtocolModel
      attribute? :documentation_url, Types::String.optional
      attribute? :changelog_url, Types::String.optional
      attribute :connection_specification, Types::Hash
      attribute :supports_normalization, Types::Bool.default(false)
      attribute :supports_dbt, Types::Bool.default(false)
      attribute :stream_type, StreamType
      attribute? :supported_destination_sync_modes, Types::Array.of(DestinationSyncMode).optional

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["connector_spec"],
          connector_spec: self
        )
      end
    end

    class Connector < ProtocolModel
      attribute :name, Types::String
      attribute :type, ConnectorType
      attribute :connection_specification, Types::Hash
    end

    class LogMessage < ProtocolModel
      attribute :level, LogLevel
      attribute :message, Types::String
      attribute? :name, Types::String.optional
      attribute? :stack_trace, Types::String.optional

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["log"],
          log: self
        )
      end
    end

    class Model < ProtocolModel
      attribute? :name, Types::String.optional
      attribute :query, Types::String
      attribute :query_type, ModelQueryType
      attribute :primary_key, Types::String
    end

    class RecordMessage < ProtocolModel
      attribute :data, Types::Hash
      attribute :emitted_at, Types::Integer

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["record"],
          record: self
        )
      end
    end

    class Stream < ProtocolModel
      # Common
      attribute :name, Types::String
      attribute? :action, StreamAction
      attribute :json_schema, Types::Hash
      attribute? :supported_sync_modes, Types::Array.of(SyncMode).optional
      # Applicable for database streams
      attribute? :source_defined_cursor, Types::Bool.optional
      attribute? :default_cursor_field, Types::Array.of(Types::String).optional
      attribute? :source_defined_primary_key, Types::Array.of(Types::Array.of(Types::String)).optional
      attribute? :namespace, Types::String.optional
      # Applicable for API streams
      attribute? :url, Types::String.optional
      attribute? :request_method, Types::String.optional
    end

    class Catalog < ProtocolModel
      attribute :streams, Types::Array.of(Stream)

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["catalog"],
          catalog: self
        )
      end
    end

    class SyncConfig < ProtocolModel
      attr_accessor :offset, :limit

      attribute :source, Connector
      attribute :destination, Connector
      attribute :model, Model
      attribute :stream, Stream
      attribute :sync_mode, SyncMode
      attribute? :cursor_field, Types::String.optional
      attribute :destination_sync_mode, DestinationSyncMode
    end

    class ControlMessage < ProtocolModel
      attribute :type, ControlMessageType
      attribute :emitted_at, Types::Integer
      attribute? :meta, Types::Hash

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["control"],
          control: self
        )
      end
    end

    class TrackingMessage < ProtocolModel
      attribute :success, Types::Integer.default(0)
      attribute :failed, Types::Integer.default(0)
      attribute? :meta, Types::Hash

      def to_multiwoven_message
        MultiwovenMessage.new(
          type: MultiwovenMessageType["tracking"],
          tracking: self
        )
      end
    end

    class MultiwovenMessage < ProtocolModel
      attribute :type, MultiwovenMessageType
      attribute? :log, LogMessage.optional
      attribute? :connection_status, ConnectionStatus.optional
      attribute? :connector_spec, ConnectorSpecification.optional
      attribute? :catalog, Catalog.optional
      attribute? :record, RecordMessage.optional
      attribute? :control, ControlMessage.optional
      attribute? :tracking, TrackingMessage.optional
    end
  end
end
