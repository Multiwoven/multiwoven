# frozen_string_literal: true

# app/serializers/audit_logs_serializer.rb
class AuditLogsSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :action, :resource_type, :resource_id, :resource, :workspace_id,
             :metadata
end
