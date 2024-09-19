# frozen_string_literal: true

class VisualComponentSerializer < ActiveModel::Serializer
  attributes :id, :component_type, :data_app_id, :model_id, :icon, :properties, :feedback_config,
             :updated_at, :created_at

  attribute :model do
    ModelSerializer.new(object.model)
  end

  def icon
    object.model&.connector&.icon
  end
end
