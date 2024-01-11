# frozen_string_literal: true

# app/serializers/workspace_serializer.rb
class WorkspaceSerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :status, :api_key, :created_at, :updated_at

  # You can also define associations if you need to include related data
  has_many :users
  belongs_to :organization
end
