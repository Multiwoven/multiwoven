# frozen_string_literal: true

module WorkspaceUsers
  class Create
    include Interactor

    def call
      find_or_create_user
      create_workspace_user
      send_invitation_email
    end

    private

    attr_accessor :workspace, :user, :email, :role

    def find_or_create_user
      initialize_attributes

      self.user = User.find_by(email:) || create_new_user
    end

    def initialize_attributes
      self.workspace = context.workspace
      self.email = context.user_params[:email]
      self.role = context.user_params[:role] || "member"
    end

    def create_new_user
      random_password = SecureRandom.hex(8)
      new_user = User.new(email:, password: random_password, password_confirmation: random_password)
      context.fail!(errors: new_user.errors.full_messages) unless new_user.save
      new_user
    end

    def create_workspace_user
      workspace_user = WorkspaceUser.new(workspace:, user:, role:)

      if workspace_user.save
        context.workspace_user = workspace_user
      else
        context.fail!(errors: workspace_user.errors.full_messages)
      end
    end

    def send_invitation_email
      WorkspaceUserMailer.send_invitation_email(user, workspace).deliver_now
    end
  end
end
