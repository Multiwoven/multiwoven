# frozen_string_literal: true

module Authentication
  class Login
    include Interactor

    def call
      validate_app_context
      return if context.failure?

      begin
        user = User.find_by(email: context.params[:email])
      rescue StandardError => e
        Rails.logger.error("Login failed: #{e.message}")
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

    def validate_app_context
      app_context = context.app_context
      return if app_context.blank?
      return if app_context == "embed"

      context.fail!(error: "Invalid X-App-Context value. Only 'embed' is supported.")
    end

    def handle_failed_attempt(user)
      if user
        user.increment_failed_attempts
        if user.failed_attempts >= Devise.maximum_attempts
          user.lock_access!
          context.fail!(error: "Account is locked due to multiple login attempts. Please retry after sometime")
        else
          context.fail!(error: "Invalid login credentials, please try again")
        end
      else
        context.fail!(error: "Invalid login credentials, please try again")
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
      app_context = context.app_context
      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)

      # If app_context is present and equals 'embed', add it to the token payload
      token = add_app_context_to_token(token, app_context) if app_context.present? && app_context == "embed"

      user.update!(unique_id: SecureRandom.uuid) if user.unique_id.nil?
      user.update!(jti: payload["jti"])
      context.token = token
    end

    def add_app_context_to_token(original_token, app_context)
      secret = Devise::JWT.config.secret
      algorithm = Devise::JWT.config.algorithm || Warden::JWTAuth.config.algorithm
      decode_key = Devise::JWT.config.decoding_secret || secret

      decoded_payload = JWT.decode(original_token, decode_key, true, algorithm:)[0]
      decoded_payload["app_context"] = app_context
      JWT.encode(decoded_payload, secret, algorithm)
    end

    def handle_account_locked
      context.fail!(error: "Account is locked due to multiple login attempts. Please retry after sometime")
    end
  end
end
