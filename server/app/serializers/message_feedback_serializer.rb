# frozen_string_literal: true

class MessageFeedbackSerializer < ActiveModel::Serializer
  attributes :id, :workspace_id, :data_app_id, :visual_component_id, :model_id, :workflow_id, :reaction,
             :feedback_content, :created_at, :updated_at, :feedback_type, :chatbot_interaction,
             :additional_remarks, :tags

  def model_id
    object.visual_component.model&.id
  end

  def workflow_id
    object.visual_component.workflow&.id
  end
end
