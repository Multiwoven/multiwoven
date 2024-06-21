# frozen_string_literal: true

module Api
  module V1
    class AuthController < ApplicationController
      include Authentication
      before_action :authenticate_user!, only: [:logout]
      skip_after_action :verify_authorized

      def login
        result = Login.call(params:)
        if result.success?
          # Treating the token as a resource in terms of JSON API response
          render json: {
            data: {
              type: "token",
              id: result.token, # or a generated ID if the token shouldn't be exposed here
              attributes: {
                token: result.token
              }
            }
          }, status: :ok
        else
          render_error(message: result.error, status: :unauthorized)
        end
      end

      def signup
        result = Signup.call(params:)
        if result.success?
          render json: {
            data: {
              type: "token",
              id: result.token,
              attributes: {
                token: result.token
              }
            }
          }, status: :created
        else
          render_error(message: "Signup failed", status: :unprocessable_entity,
                       details: format_errors(result.user))
        end
      end

      def logout
        result = Logout.call(current_user:)
        if result.success?
          render json: { data: { type: "message", id: SecureRandom.uuid, attributes: { message: result.message } } },
                 status: :ok
        else
          render_error(message: result.message, status: :internal_server_error)
        end
      end

      def forgot_password
        user = User.find_by(email: params[:email])

        if user
          user.send_reset_password_instructions
          render json: { data: { type: "message",
                                 id: user.id,
                                 attributes: { message: "Reset password instructions sent to email." } } },
                 status: :ok
        else
          render_error(message: "Email not found", status: :not_found)
        end
      end

      def reset_password
        user = User.with_reset_password_token(params[:reset_password_token])

        if user&.reset_password(params[:password], params[:password_confirmation])
          render json: { data: { type: "message",
                                 id: user.id,
                                 attributes: { message: "Password successfully reset." } } },
                 status: :ok
        else
          render_error(message: "Invalid token or password mismatch.", status: :unprocessable_entity)
        end
      end

      def verify_code
        unless params[:email] && params[:confirmation_code]
          return render json: { errors: [{ detail: "Missing required parameters" }] }, status: :bad_request
        end

        user = User.find_by(email: params[:email])

        if user&.confirmation_code == params[:confirmation_code]
          user.update!(confirmed_at: Time.current, confirmation_code: nil)
          render json: { data: { type: "message",
                                 id: user.id,
                                 attributes: { message: "Account verified successfully!" } } },
                 status: :ok
        else
          render_error(message: "Invalid confirmation code.", status: :unprocessable_entity)
        end
      end

      def resend_verification
        result = Authentication::ResendVerificationCode.call(params:)
        if result.success?
          render json: { data: { type: "message",
                                 id: SecureRandom.uuid,
                                 attributes: { message: "Verification code resent successfully." } } },
                 status: :ok
        else
          render json: { errors: [{ detail: result.error || result.errors }] }, status: :unprocessable_entity
        end
      end
    end
  end
end
