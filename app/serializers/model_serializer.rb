# frozen_string_literal: true

class ModelSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :query, :query_type, :created_at, :updated_at
end
