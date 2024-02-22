# frozen_string_literal: true

# app/serializers/catalog_serializer.rb
class CatalogSerializer < ActiveModel::Serializer
  attributes :id, :connector_id, :workspace_id, :catalog, :catalog_hash
end
