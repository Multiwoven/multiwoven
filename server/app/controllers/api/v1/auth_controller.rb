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
          render json: result.user, status: :created
        else
          render_error(message: result.errors, status: :unprocessable_content,
                       details: nil)
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

      # Override current_workspace method for this action to prevent workspace validation errors
      def current_workspace
        # For simulate_request, we don't validate workspace
        # This returns nil but doesn't raise an error
        @current_workspace = nil
      end
      
      def simulate_request
        # Clear any existing sessions before simulating a new login
        sign_out(current_user) if user_signed_in?
        
        # Process the simulate login request
        result = Authentication::SimulateLogin.call(params:)
        
        if result.success?
          # Return the JWT token for authentication
          render json: {
            data: {
              type: "token",
              id: result.token,
              attributes: {
                token: result.token,
                user: {
                  id: result.user.id,
                  email: result.user.email,
                  name: result.user.name
                }
              }
            }
          }, status: :ok
        else
          render_error(message: result.error, status: :unauthorized)
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
        if user && !user.reset_password_period_valid?
          render_error(message: "Token has expired.", status: :unprocessable_content)
        elsif user&.reset_password(params[:password], params[:password_confirmation])
          render json: { data: { type: "message",
                                 id: user.id,
                                 attributes: { message: "Password successfully reset." } } },
                 status: :ok
        else
          render_error(message: "Invalid token or password mismatch.", status: :unprocessable_content)
        end
      end

      def verify_user
        confirmed_user = User.confirm_by_token(params[:confirmation_token])
        if confirmed_user.errors.empty?
          render json: { data: { type: "message",
                                 id: confirmed_user.id,
                                 attributes: { message: "Account verified successfully!" } } },
                 status: :ok
        else
          render_error(message: "Invalid confirmation code.", status: :unprocessable_content)
        end
      end

      def resend_verification
        result = Authentication::ResendVerificationEmail.call(params:)
        if result.success?
          render json: { data: { type: "message",
                                 id: SecureRandom.uuid,
                                 attributes: { message: "Email verification link sent successfully!" } } },
                 status: :ok
        else
          render_error(message: result.error, status: :unprocessable_content)
        end
      end
    end
  end
end
