# frozen_string_literal: true

# app/interactors/authentication/login.rb
module Authentication
  class Login
    include Interactor

    def call
      begin
        user = User.find_by(email: context.params[:email])
      rescue StandardError => e
        Rails.logger.error("Login Interactor Exception: #{e.message}")
        Utils::ExceptionReporter.report(e)
        context.fail!(error: "An error occurred while finding the user.")
        return
      end
      authenticate(user)
    end

    def authenticate(user)
      if user&.access_locked?
        context.fail!(error: "Account is locked due to multiple login attempts. Please retry after sometime")
      elsif user&.valid_password?(context.params[:password])
        if user.verified?
          token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
          user.update!(unique_id: SecureRandom.uuid) if user.unique_id.nil?
          user.update!(jti: payload["jti"])
          context.token = token
        else
          context.fail!(error: "Account not verified. Please verify your account.")
        end
      else
        handle_failed_attempt(user)
      end
    end

    private

    def handle_failed_attempt(user)
      if user
        user.increment_failed_attempts
        if user.failed_attempts >= Devise.maximum_attempts
          user.lock_access!
          context.fail!(error: "Account is locked due to multiple login attempts. Please retry after sometime")
        else
          context.fail!(error: "Invalid email or password")
        end
      else
        context.fail!(error: "Invalid email or password")
      end
    end
  end
end
