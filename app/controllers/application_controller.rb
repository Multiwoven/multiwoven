# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include ExceptionHandler

  before_action :authenticate_user!
  around_action :handle_with_exception

  private

  # Override Devise's method to handle authentication
  def authenticate_user!
    return if user_signed_in?

    # If not authenticated, return a 401 unauthorized response
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def current_workspace
    @current_workspace ||= current_user.workspaces.first
  end

  protected

  def render_error(message:, status:, details: nil)
    error_response = {
      errors: [
        {
          status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status],
          title: "Error",
          detail: message
        }
      ]
    }
    error_response[:errors][0][:source] = details if details
    render json: error_response, status:
  end
end
