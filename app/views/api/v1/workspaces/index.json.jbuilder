# frozen_string_literal: true

json.array! @workspaces do |workspace|
  # TODO: move to partial

  json.id workspace.id
  json.name workspace.name
  json.slug workspace.slug
  json.status workspace.status
  json.created_at workspace.created_at
  json.updated_at workspace.updated_at
end
