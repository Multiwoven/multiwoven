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
    end

    class ConnectorSpecification < ProtocolModel
      attribute? :documentation_url, Types::String.optional
      attribute? :changelog_url, Types::String.optional
      attribute :connection_specification, Types::Hash
      attribute :supports_normalization, Types::Bool.default(false)
      attribute :supports_dbt, Types::Bool.default(false)
      attribute? :supported_destination_sync_modes, Types::Array.of(DestinationSyncMode).optional
    end

    class Connector < ProtocolModel
      attribute :name, Types::String
      attribute :type, ConnectorType
      attribute :connection_specification, Types::Hash
    end

    class LogMessage < ProtocolModel
      attribute :level, Types::String.enum("fatal", "error", "warn", "info", "debug", "trace")
      attribute :message, Types::String
      attribute? :stack_trace, Types::String.optional
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
    end

    class Stream < ProtocolModel
      attribute :name, Types::String
      attribute :json_schema, Types::Array.of(Types::Hash)
      attribute? :supported_sync_modes, Types::Array.of(SyncMode).optional
      attribute? :source_defined_cursor, Types::Bool.optional
      attribute? :default_cursor_field, Types::Array.of(Types::String).optional
      attribute? :source_defined_primary_key, Types::Array.of(Types::Array.of(Types::String)).optional
      attribute? :namespace, Types::String.optional
    end

    class Catalog < ProtocolModel
      attribute :streams, Types::Array.of(Stream)
    end

    class SyncConfig < ProtocolModel
      attribute :source, Connector
      attribute :destination, Connector
      attribute :model, Model
      attribute :sync_mode, SyncMode
      attribute? :cursor_field, Types::Array.of(Types::String).optional
      attribute :destination_sync_mode, DestinationSyncMode
    end
  end
end
