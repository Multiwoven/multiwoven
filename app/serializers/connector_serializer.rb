# frozen_string_literal: true

class ConnectorSerializer < ActiveModel::Serializer
  attributes :id, :name, :connector_type, :workspace_id, :created_at, :updated_at, :configuration

  attribute :connector_definition_name, key: :connector_name
  attribute :connector_definition_icon, key: :icon

  def connector_definition_name
    object.connector_definition[:data][:name]
  end

  def connector_definition_icon
    object.connector_definition[:data][:icon]
  end
end
