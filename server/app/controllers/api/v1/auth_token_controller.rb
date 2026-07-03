# frozen_string_literal: true

module Api
  module V1
    class AuthTokenController < ApplicationController
      skip_before_action :validate_contract
      skip_before_action :ensure_eula_accepted
      skip_after_action :verify_authorized

      def show
        jwt = cookies[AuthCookies::AUTH_COOKIE_NAME].presence ||
              request.headers["Authorization"]&.split(" ", 2)&.last
        return render_error(message: "Unauthorized", status: :unauthorized) if jwt.blank?

        render json: { token: jwt }, status: :ok
      end
    end
  end
end
