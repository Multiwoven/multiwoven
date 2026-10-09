# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      class AuthController < EnterpriseBaseController
        include Authentication
        include AuthCookies
        skip_before_action :authenticate_user!
        skip_after_action :verify_authorized
        skip_before_action :ensure_eula_accepted

        def invite_signup
          result = InviteSignup.call(invite_signup_params:)
          if result.success?
            write_auth_cookie(result.token)
            write_csrf_cookie
            render_auth_token(result.token, status: :created)
          else
            render_error(message: "Invite User Signup failed: #{result.errors}",
                         details: result.errors, status: :unprocessable_content)
          end
        end

        def sso_login
          saml_request = SsoLogin.call(params:)
          if saml_request.success?
            render json: { data: { url: saml_request.redirect_url } }, status: :ok
          else
            render_error(message: saml_request.error, status: :unprocessable_content)
          end
        end

        def acs_callback
          result = AcsCallback.call(params:)
          if result.success?
            write_auth_cookie(result.token)
            write_csrf_cookie
            success_url = "https://#{ENV['UI_HOST']}/sso-sign-in?token=#{result.token}&success=true"
            redirect_to success_url, allow_other_host: true
          else
            failure_url = "https://#{ENV['UI_HOST']}/sso-sign-in?success=false"
            redirect_to failure_url, allow_other_host: true
          end
        end

        private

        def invite_signup_params
          params.require(:user).permit(:name, :email, :password, :password_confirmation, :invitation_token)
        end
      end
    end
  end
end
