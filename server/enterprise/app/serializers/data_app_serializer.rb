# frozen_string_literal: true

class DataAppSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status, :meta_data, :visual_components, :updated_at, :created_at

  def visual_components
    object.visual_components.map do |component|
      VisualComponentSerializer.new(component).as_json
    end
  end
end
