# frozen_string_literal: true

# app/serializers/workspace_user_serializer.rb
class WorkspaceUserSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :workspace_id, :role
end
