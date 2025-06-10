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
  attributes :id, :name, :slug, :status, :api_key, :created_at, :updated_at, :description, :region, :organization_id,
             :organization_name, :members_count, :workspace_logo_url, :organization_logo_url

  def organization_id
    object.organization.id
  end

  def organization_name
    object.organization.name
  end

  def members_count
    object.users.count
  end

  def workspace_logo_url
    return nil unless object.file.attached?

    blob = object.file.blob
    "#{ENV['API_HOST']}/rails/active_storage/blobs/#{blob.signed_id}/#{blob.filename}"
  end

  def organization_logo_url

    return nil unless object.organization.file.attached?

    blob = object.organization.file.blob
    "#{ENV['API_HOST']}/rails/active_storage/blobs/#{blob.signed_id}/#{blob.filename}"
  end
end
