# frozen_string_literal: true

class MessageFeedbackSerializer < ActiveModel::Serializer
  attributes :id, :workspace_id, :data_app_id, :visual_component_id, :model_id, :reaction,
             :feedback_content, :created_at, :updated_at, :feedback_type, :chatbot_interaction,
             :additional_remarks, :tags
end
