# frozen_string_literal: true

class ModelSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :query, :query_type, :configuration, :primary_key, :created_at, :updated_at

  attribute :connector do
    ConnectorSerializer.new(object.connector).attributes
  end

  def configuration
    if object.ai_ml?
      connector = object.connector
      json_schema = connector.catalog.json_schema(connector.connector_name)
      existing_config = object.configuration

      existing_config.merge({ json_schema: })
    else
      object.configuration
    end
  end
end
