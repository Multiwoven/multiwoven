# frozen_string_literal: true

# app/interactors/workspaces/update.rb

module Workspaces
  class Update
    include Interactor

    def call
      workspace = Workspace.find_by(id: context.id)
      if workspace&.update(context.workspace_params)
        context.workspace = workspace
      else
        context.fail!(workspace:)
      end
    end
  end
end
