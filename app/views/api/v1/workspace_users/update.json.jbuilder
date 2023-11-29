# frozen_string_literal: true

# app/views/api/v1/workspace_users/update.json.jbuilder

json.workspace_user do
  # TODO: move to partial
  json.id @workspace_user.id
  json.user_id @workspace_user.user_id
  json.workspace_id @workspace_user.workspace_id
  json.role @workspace_user.role
  json.created_at @workspace_user.created_at
  json.updated_at @workspace_user.updated_at
end

json.message "User role updated."
