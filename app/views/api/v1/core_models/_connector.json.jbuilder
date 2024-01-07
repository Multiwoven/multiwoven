# frozen_string_literal: true

json.extract! connector, :id, :name, :connector_type, :workspace_id, :created_at, :updated_at, :configuration
json.connector_definition do
  json.name connector.connector_definition[:data][:name]
  json.icon connector.connector_definition[:data][:icon]
end
