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
      if account_locked?(user)
        handle_account_locked
      elsif valid_password?(user)
        process_successful_authentication(user)
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

    def account_locked?(user)
      user&.access_locked?
    end

    def valid_password?(user)
      user&.valid_password?(context.params[:password])
    end

    def process_successful_authentication(user)
      if user_verified_or_verification_disabled?(user)
        issue_token_and_update_user(user)
      else
        context.fail!(error: "Account not verified. Please verify your account.")
      end
    end

    def user_verified_or_verification_disabled?(user)
      user.verified? || !User.email_verification_enabled?
    end

    def issue_token_and_update_user(user)
      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      user.update!(unique_id: SecureRandom.uuid) if user.unique_id.nil?
      user.update!(jti: payload["jti"])
      context.token = token
    end

    def handle_account_locked
      context.fail!(error: "Account is locked due to multiple login attempts. Please retry after sometime")
    end
  end
end
