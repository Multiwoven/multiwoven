# frozen_string_literal: true

# app/interactors/workspaces/create.rb
module Workspaces
  class Create
    include Interactor

    def call
      workspace = Workspace.new(context.workspace_params)
      if workspace.save
        create_workspace_user_as_admin(workspace, context.user)
        context.workspace = workspace
      else
        context.fail!(errors: workspace.errors.full_messages)
      end
    end

    private

    def create_workspace_user_as_admin(workspace, user)
      WorkspaceUser.create!(
        workspace:,
        user:,
        role: "admin"
      )
    end
  end
end
