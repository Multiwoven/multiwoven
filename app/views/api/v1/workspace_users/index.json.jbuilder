# frozen_string_literal: true

# views/api/v1/workspace_users/index.json.jbuilder

json.array! @workspace_users do |workspace_user|
  # TODO: move to partial

  json.id workspace_user.id
  json.email workspace_user.user.email
  json.role workspace_user.role
end
