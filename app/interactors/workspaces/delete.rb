# frozen_string_literal: true

module Workspaces
  class Delete
    include Interactor

    def call
      workspace = context.user.workspaces.find_by(id: context.id)

      if workspace.present?
        workspace.destroy!
      else
        context.fail!(errors: ["Workspace not found"])
      end
    end
  end
end
