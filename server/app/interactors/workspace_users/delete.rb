# frozen_string_literal: true

module WorkspaceUsers
  class Delete
    include Interactor

    def call
      # TODO: Add user scope for workspace user
      workspace_user = WorkspaceUser.find_by(id: context.id)

      return if workspace_user&.destroy

      context.fail!(errors: ["Failed to remove user from workspace"])
    end
  end
end
