# frozen_string_literal: true

class FeedbackSerializer < ActiveModel::Serializer
  attributes :id, :workspace_id, :data_app_id, :visual_component_id, :model_id, :reaction,
             :feedback_content, :created_at, :updated_at, :feedback_type, :session_id,
             :additional_remarks, :tags
end
