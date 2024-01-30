# frozen_string_literal: true

class ModelSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :query, :query_type, :primary_key, :created_at, :updated_at

  attribute :connector do
    ConnectorSerializer.new(object.connector).attributes
  end
end
