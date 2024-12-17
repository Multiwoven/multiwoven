# frozen_string_literal: true

# app/serializers/audit_logs_serializer.rb
class AuditLogsSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :user_name, :action, :resource_type, :resource_id, :resource, :resource_link,
             :workspace_id, :metadata, :created_at, :updated_at

  def user_name
    object.user&.name
  end
end
