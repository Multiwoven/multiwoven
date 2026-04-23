# frozen_string_literal: true

class ChatMessageSerializer < ActiveModel::Serializer
  attributes :id, :workspace_id, :visual_component_id, :content, :role, :updated_at,
             :created_at

  attribute :data_app_session_id do
    object.session_id if data_app_session?
  end

  attribute :workflow_session_id do
    object.session_id if workflow_session?
  end

  def data_app_session_id
    object.session_id
  end

  def workflow_session_id
    object.session_id
  end

  def content
    object.content.gsub("=>", ":").gsub("nil", "null")
  end

  private

  def data_app_session?
    object.session_type == "DataAppSession"
  end

  def workflow_session?
    object.session_type == "Agents::WorkflowSession"
  end
end
