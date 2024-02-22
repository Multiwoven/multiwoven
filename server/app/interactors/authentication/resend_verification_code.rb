# frozen_string_literal: true

# app/interactors/authentication/resend_verification_code.rb

module Authentication
  class ResendVerificationCode
    include Interactor

    def call
      find_user
      assign_new_confirmation_code
      save_user
      send_confirmation_email
    end

    private

    attr_accessor :user

    def find_user
      self.user = User.find_by(email: context.params[:email])
      context.fail!(error: "User not found.", status: :not_found) unless user
    end

    def assign_new_confirmation_code
      user.confirmation_code = generate_confirmation_code
    end

    def save_user
      context.fail!(errors: user.errors.full_messages) unless user.save
    end

    def send_confirmation_email
      UserMailer.send_confirmation_code(user).deliver_now
    end

    def generate_confirmation_code
      rand(100_000..999_999).to_s
    end
  end
end
