# frozen_string_literal: true

module WorkspaceUsers
  class Update
    include Interactor

    def call
      # TODO: Add user scope for workspace user
      workspace_user = WorkspaceUser.find_by(id: context.id)
      update_workspace_user(workspace_user)
    end

    def update_workspace_user(workspace_user)
      if workspace_user&.update(role: context.role)
        context.workspace_user = workspace_user
      else
        context.fail!(errors: workspace_user&.errors&.full_messages || ["WorkspaceUser not found"])
      end
    end
  end
end
