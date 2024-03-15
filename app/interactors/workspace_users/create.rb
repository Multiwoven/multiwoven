# frozen_string_literal: true

module WorkspaceUsers
  class Create
    include Interactor

    def call
      find_or_create_user
      create_workspace_user
      send_invitation_email if user
    end

    private

    attr_accessor :workspace, :user, :name, :email, :role

    def find_or_create_user
      initialize_attributes

      if name.blank? || email.blank? || role.blank?
        context.fail!(message: "Invalid parameters")
        return
      end

      self.user = User.find_by(email:) || create_new_user
    end

    def initialize_attributes
      self.workspace = context.workspace
      self.email = context.user_params[:email]
      self.role = context.user_params[:role] || "member"
      self.name = context.user_params[:name]
    end

    def create_new_user
      random_password = generate_complex_password(8)
      new_user = User.new(email:, password: random_password, password_confirmation: random_password, name:)
      context.fail!(new_user:) unless new_user.save
      new_user
    end

    def create_workspace_user
      return if context.failure? || user.nil?

      workspace_user = WorkspaceUser.new(workspace:, user:, role:)

      if workspace_user.save
        context.workspace_user = workspace_user
      else
        context.fail!(workspace_user:)
      end
    end

    def send_invitation_email
      WorkspaceUserMailer.send_invitation_email(user, workspace).deliver_now
    end

    def generate_complex_password(length = 16)
      # Define character sets
      uppercase_letters = ("A".."Z").to_a
      lowercase_letters = ("a".."z").to_a
      digits = ("0".."9").to_a
      special_characters = ["#", "?", "!", "@", "$", "%", "^", "&", "*", "-"]

      # Ensure the password includes at least one character from each set
      password = [
        uppercase_letters.sample,
        lowercase_letters.sample,
        digits.sample,
        special_characters.sample
      ]

      # Fill the rest of the password length with a random selection of all characters
      remaining_length = length - password.length
      all_characters = uppercase_letters + lowercase_letters + digits + special_characters
      remaining_length.times { password << all_characters.sample }

      # Shuffle to avoid a predictable pattern
      password.shuffle.join
    end
  end
end
