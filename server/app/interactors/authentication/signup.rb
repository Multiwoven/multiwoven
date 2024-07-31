# frozen_string_literal: true

module Authentication
  class Signup
    include Interactor

    def call
      ActiveRecord::Base.transaction do
        create_new_user
        create_organization_and_workspace
        save_user
        if user.persisted?
          user.send_confirmation_instructions
          context.message = "Signup successful! Please check your email to confirm your account."
        else
          context.fail!(errors: user.errors.full_messages)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      context.fail!(error: e.message)
    end

    private

    attr_accessor :user, :organization, :workspace

    def create_new_user
      self.user = User.new(
        name: context.params[:name],
        email: context.params[:email],
        password: context.params[:password],
        password_confirmation: context.params[:password_confirmation]
      )
    end

    def create_organization_and_workspace
      create_organization
      return unless organization.errors.empty?

      create_workspace
    end

    def create_organization
      self.organization = Organization.new(name: context.params[:company_name])
      organization.save
    end

    def create_workspace
      self.workspace = organization.workspaces.new(name: "default")
      workspace.save
    end

    def save_user
      if user.save && organization.errors.empty?
        create_workspace_user
        context.user = user
        context.message = "Signup successful!"
      else
        user.errors.add(:company_name, organization.errors[:name].first) if organization.errors[:name].present?
        context.fail!(errors: "Signup failed: #{user.errors.full_messages.join(', ')}")
      end
    end

    def create_workspace_user
      WorkspaceUser.create(
        user:,
        workspace:,
        role: Role.find_by(role_name: "Admin")
      )
    end
  end
end
