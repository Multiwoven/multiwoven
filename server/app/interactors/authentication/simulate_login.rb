# frozen_string_literal: true

# app/interactors/authentication/simulate_login.rb
module Authentication
  class SimulateLogin
    include Interactor

    def call
      # Extract token - could be at top level or in auth hash
      token = extract_token_from_params(context.params)
      
      if token.blank?
        context.fail!(error: "Token is required")
        return
      end

      # Find user by token
      begin
        user = User.find_by(simulate_req_token: token)
      rescue StandardError => e
        Rails.logger.error("SimulateLogin Interactor Exception: #{e.message}")
        Utils::ExceptionReporter.report(e)
        context.fail!(error: "An error occurred while finding the user.")
        return
      end

      # Check if user exists
      if user.nil?
        context.fail!(error: "Invalid or expired token")
        return
      end
      
      # Sign out any existing users to prevent session conflicts
      # Extract authToken from params to revoke existing sessions
      auth_token = extract_auth_token_from_params(context.params)
      Warden::JWTAuth::TokenRevoker.new.call(auth_token) if auth_token.present?
      
      # Process authentication
      process_successful_authentication(user)

      # Clear the token after successful authentication to prevent reuse
      user.update(simulate_req_token: nil)
    end

    private

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
    
    def extract_token_from_params(params)
      # Check for token in different places based on how parameters might be structured
      if params[:auth].present? && params[:auth][:token].present?
        params[:auth][:token]
      else
        params[:token]
      end
    end
    
    def extract_auth_token_from_params(params)
      # Extract authToken from different places based on parameter structure
      if params[:auth].present? && params[:auth][:authToken].present?
        params[:auth][:authToken]
      else
        params[:authToken]
      end
    end

    def issue_token_and_update_user(user)
      token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
      user.update!(unique_id: SecureRandom.uuid) if user.unique_id.nil?
      user.update!(jti: payload["jti"])
      context.token = token
      context.user = user
    end
  end
end
