# frozen_string_literal: true

source_connector = Multiwoven::Integrations::Protocol::Connector.new(
  name: "AWS Athena",
  type: Multiwoven::Integrations::Protocol::ConnectorType["source"],
  connection_specification: {
    "access_key": ENV["ATHENA_ACCESS"],
    "secret_access_key": ENV["ATHENA_SECRET"],
    "region": "us-east-2",
    "workgroup": "test_workgroup",
    "catalog": "AwsDatacatalog",
    "schema": "test_database",
    "output_location": "s3://s3bucket-ai2-test"
  }
)

model = Multiwoven::Integrations::Protocol::Model.new(
  name: "Anthena Account",
  query: "select id, name from Account LIMIT 10",
  query_type: "raw_sql",
  primary_key: "id"
)

destination_connector = Multiwoven::Integrations::Protocol::Connector.new(
  name: "Sample Destination Connector",
  type: Multiwoven::Integrations::Protocol::ConnectorType["destination"],
  connection_specification: {}
)


stream = Multiwoven::Integrations::Protocol::Stream.new(
  name: "example_stream",
  action: "create",
  "json_schema": { "field1": "type1" },
  "supported_sync_modes": %w[full_refresh incremental],
  "source_defined_cursor": true,
  "default_cursor_field": ["field1"],
  "source_defined_primary_key": [["field1"], ["field2"]],
  "namespace": "exampleNamespace",
  "url": "https://api.example.com/data",
  "method": "GET"
)

sync_config = Multiwoven::Integrations::Protocol::SyncConfig.new(
  source: source_connector,
  destination: destination_connector,
  model: model,
  stream: stream,
  sync_mode: Multiwoven::Integrations::Protocol::SyncMode["full_refresh"],
  destination_sync_mode: Multiwoven::Integrations::Protocol::DestinationSyncMode["upsert"]
)

Multiwoven::Integrations::Source::AWSAthena::Client.new.read(sync_config)
