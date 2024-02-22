# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  api_key    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# app/serializers/workspace_serializer.rb
class WorkspaceSerializer < ActiveModel::Serializer
  attributes :id, :name, :slug, :status, :api_key, :created_at, :updated_at

  # You can also define associations if you need to include related data
  has_many :users
  belongs_to :organization
end
