# frozen_string_literal: true

module Authentication
  class ResendVerificationEmail
    include Interactor

    def call
      user = User.find_by(email: context.params[:email])
      context.fail!(error: "User not found.", status: :not_found) unless user
      if !user.confirmed?
        user.send_confirmation_instructions
        context.message = "Please check your email to confirm your account."
      else
        context.fail!(error: "Account already confirmed.", status: :unprocessable_content)
      end
    end
  end
end
