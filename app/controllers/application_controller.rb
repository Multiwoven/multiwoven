# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers

  before_action :authenticate_user!

  private

  # Override Devise's method to handle authentication
  def authenticate_user!
    return if user_signed_in?

    # If not authenticated, return a 401 unauthorized response
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
