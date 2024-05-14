# frozen_string_literal: true

class ResourceSerializer < ActiveModel::Serializer
  attributes :id, :resources_name, :permissions
end
