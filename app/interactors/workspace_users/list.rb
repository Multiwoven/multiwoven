# frozen_string_literal: true

module WorkspaceUsers
  class List
    include Interactor

    def call
      workspace = context.workspace
      context.workspace_users = workspace.workspace_users.includes(:user)
    end
  end
end
