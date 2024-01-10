# frozen_string_literal: true

module Authentication
  class Signup
    include Interactor

    def call
      ActiveRecord::Base.transaction do
        create_new_user
        create_organization_and_workspace
        assign_confirmation_code
        save_user
        send_confirmation_email
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

    def assign_confirmation_code
      user.confirmation_code = generate_confirmation_code
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
        user.errors.add(:company_name, organization.errors[:name].first)
        context.fail!(errors: user.errors.full_messages)
      end
    end

    def create_workspace_user
      WorkspaceUser.create(
        user:,
        workspace:,
        role: WorkspaceUser::ADMIN
      )
    end

    def send_confirmation_email
      UserMailer.send_confirmation_code(user).deliver_now
    end

    def generate_confirmation_code
      rand(100_000..999_999).to_s
    end
  end
end
