# frozen_string_literal: true

module Authentication
  class Signup
    include Interactor

    def call
      ActiveRecord::Base.transaction do
        create_new_user
        create_organization_and_workspace
        # Commenting out the assign_confirmation_code and send_confirmation_email steps
        # assign_confirmation_code
        # send_confirmation_email
        save_user
        confirm_user_and_generate_token if user.persisted?
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

    def confirm_user_and_generate_token
      # Confirm the user
      user.update!(confirmed_at: Time.current)
      # Generate JWT token, similar to the Login interactor
      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      user.update!(jti: payload["jti"])

      context.token = token
      context.message = "Signup and confirmation successful!"
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

    def send_confirmation_email
      UserMailer.send_confirmation_code(user).deliver_now
    end

    def generate_confirmation_code
      rand(100_000..999_999).to_s
    end
  end
end
