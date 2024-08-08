# frozen_string_literal: true

module Users
  class ResendUserInvite
    include Interactor

    def call
      user = context.workspace.users.find_by(id: context.user_id, status: "invited")
      if user.present?
        workspace_user = WorkspaceUser.find_by(user:, workspace: context.workspace)
        user.update(invitation_created_at: Time.zone.now, invitation_sent_at: Time.zone.now)
        user.deliver_invitation(workspace: context.workspace, role: workspace_user.role)
        context.user = user
      else
        context.fail!(message: "Invalid User")
      end
    rescue StandardError => e
      context.fail!(error: e.message)
    end
  end
end
