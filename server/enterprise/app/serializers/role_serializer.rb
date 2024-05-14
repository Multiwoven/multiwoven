# frozen_string_literal: true

class RoleSerializer < ActiveModel::Serializer
  attributes :id, :role_name, :role_desc, :policies, :updated_at, :created_at
end
