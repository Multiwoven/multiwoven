# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::AuthController, type: :controller do
  let(:user) { create(:user, :invited, name: nil) }
  let(:workspace) { create(:workspace) }
  let(:organization) { workspace.organization }
  let(:sso_user) { workspace.workspace_users.first.user }
  let!(:invitation_token) { user.raw_invitation_token }
  let!(:email) { user.email }

  let(:valid_params) do
    {
      user: {
        name: "Test User",
        email:,
        invitation_token:,
        password: "Password123!",
        password_confirmation: "Password123!"
      }
    }
  end

  let(:invalid_params) do
    {
      user: {
        name: "Test User",
        email:,
        password: "Password@123",
        password_confirmation: "Password@123",
        invitation_token: "invalid_token"
      }
    }
  end

  let(:valid_saml_response) do
    Base64.encode64(
      <<~XML
        <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
          <saml:Issuer>https://login.microsoftonline.com</saml:Issuer>
          <saml:AttributeStatement>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
              <saml:AttributeValue>#{sso_user.email}</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
              <saml:AttributeValue>#{sso_user.name.split(' ').first}</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
              <saml:AttributeValue>#{sso_user.name.split(' ').last}</saml:AttributeValue>
            </saml:Attribute>
          </saml:AttributeStatement>
        </saml:Assertion>
      XML
    )
  end

  let(:invite_saml_response) do
    Base64.encode64(
      <<~XML
        <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
          <saml:Issuer>https://login.microsoftonline.com</saml:Issuer>
          <saml:AttributeStatement>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
              <saml:AttributeValue>#{sso_user.email}</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
              <saml:AttributeValue>Test</saml:AttributeValue>
            </saml:Attribute>
            <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
              <saml:AttributeValue>User</saml:AttributeValue>
            </saml:Attribute>
          </saml:AttributeStatement>
        </saml:Assertion>
      XML
    )
  end

  let(:invalid_saml_response) do
    Base64.encode64(
      <<~XML
        <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
          <saml:Issuer>https://login.microsoftonline.com</saml:Issuer>
          <invalid>Invalid</invalid>
        </saml:Assertion>
      XML
    )
  end

  let(:valid_one_login_response) do
    instance_double(OneLogin::RubySaml::Response, is_valid?: true)
  end

  let(:invalid_one_login_response) do
    instance_double(OneLogin::RubySaml::Response, is_valid?: false)
  end

  before do
    create(:sso_configuration, organization:)
    allow(OneLogin::RubySaml::Response).to receive(:new).and_return(valid_one_login_response)
  end

  describe "POST #invite_signup" do
    def set_cookie_lines
      Array(response.headers["Set-Cookie"]).flat_map { |v| v.to_s.split("\n") }.reject(&:empty?)
    end

    context "with valid parameters" do
      it "creates a new user and returns the user's token" do
        post :invite_signup, params: valid_params
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:type]).to eq("token")
        expect(response_hash[:data][:attributes][:token]).not_to be_nil
        expect(response_hash[:data][:attributes][:token]).not_to be_nil
        user.reload
        expect(user.invitation_token).to eq(nil)
        expect(user.name).to eq("Test User")
      end

      it "sets HttpOnly auth and csrf-token cookies" do
        post :invite_signup, params: valid_params

        auth_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::AUTH_COOKIE_NAME}=") }
        csrf_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::CSRF_COOKIE_NAME}=") }

        expect(auth_line).not_to be_nil
        expect(auth_line).to match(/HttpOnly/i)
        expect(auth_line).to match(/SameSite=Lax/i)

        expect(csrf_line).not_to be_nil
        expect(csrf_line).not_to match(/HttpOnly/i)
      end

      it "does not set a loggedIn cookie server-side (FE-owned marker)" do
        post :invite_signup, params: valid_params
        logged_line = set_cookie_lines.find { |l| l.start_with?("loggedIn=") }
        expect(logged_line).to be_nil
      end
    end

    context "with invalid token" do
      it "does not create a user and returns an error" do
        post :invite_signup, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail))
          .to eq("Invite User Signup failed: Invitation expired or Invalid user")
        expect(response_hash.dig(:errors, 0, :source)).to eq("Invitation expired or Invalid user")
      end
    end

    context "with password not match token" do
      it "does not create a user and returns an error" do
        valid_params[:user][:password_confirmation] = "test"
        post :invite_signup, params: valid_params
        expect(response).to have_http_status(:bad_request)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail)).to eq("password and password_confirmation must match")
      end
    end

    context "with invite expired" do
      it "does not create a user and returns an error" do
        user.update!(invitation_created_at: 31.days.ago)
        post :invite_signup, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail))
          .to eq("Invite User Signup failed: Invitation expired or Invalid user")
        expect(response_hash.dig(:errors, 0, :source)).to eq("Invitation expired or Invalid user")
      end
    end

    context "with user mail invalid" do
      it "does not create a user and returns an error" do
        valid_params[:user][:email] = "test@gmail.com"
        post :invite_signup, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail))
          .to eq("Invite User Signup failed: Invitation expired or Invalid user")
        expect(response_hash.dig(:errors, 0, :source)).to eq("Invitation expired or Invalid user")
      end
    end
  end

  describe "POST #sso_login" do
    context "when an error appears" do
      it "returns unauthorized if user not found" do
        post :sso_login, params: { email: "Dummyemail@not_email.com" }
        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors][0][:detail]).to eq("User not found")
      end

      it "returns unauthorized if sso_config is not found" do
        SsoConfiguration.destroy_all
        post :sso_login, params: { email: sso_user.email }
        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors][0][:detail]).to eq("No SAML SSO enabled organization could be found")
      end
    end

    context "when it is an authenticated user" do
      it "returns success" do
        post :sso_login, params: { email: sso_user.email }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:url]).to include("?SAMLRequest=")
      end
    end
  end

  describe "GET #acs_callback" do
    # NOTE: `&token=<jwt>` is retained in the redirect URL for backwards-compat
    # with the current SSOSignIn.tsx that still reads `params.get('token')`.
    # The HttpOnly `authToken` cookie is set on the 302 response IN ADDITION.
    # When the FE cutover ships, drop `&token=` from the URL and revert these
    # assertions to `not_to include("token=")`.
    def set_cookie_lines
      Array(response.headers["Set-Cookie"]).flat_map { |v| v.to_s.split("\n") }.reject(&:empty?)
    end

    context "when SAML response is valid" do
      it "redirects to the SPA including the JWT in the URL (backwards-compat)" do
        allow(Warden::JWTAuth::UserEncoder)
          .to receive_message_chain(:new, :call)
          .and_return(["mock_token", { "jti" => "test-jti" }])
        post :acs_callback, params: { SAMLResponse: valid_saml_response }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"])
          .to include("https://#{ENV['UI_HOST']}/sso-sign-in?token=mock_token&success=true")
      end

      it "sets HttpOnly auth and csrf-token cookies on the redirect" do
        allow(Warden::JWTAuth::UserEncoder)
          .to receive_message_chain(:new, :call)
          .and_return(["mock_token", { "jti" => "test-jti" }])
        post :acs_callback, params: { SAMLResponse: valid_saml_response }

        auth_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::AUTH_COOKIE_NAME}=") }
        csrf_line = set_cookie_lines.find { |l| l.start_with?("#{AuthCookies::CSRF_COOKIE_NAME}=") }

        expect(auth_line).to match(/#{AuthCookies::AUTH_COOKIE_NAME}=mock_token/)
        expect(auth_line).to match(/HttpOnly/i)
        expect(csrf_line).not_to be_nil
      end
    end

    context "when SAML response is valid for invite" do
      it "redirects to the SPA including the JWT in the URL (backwards-compat)" do
        sso_user.update(status: "invited")
        allow(Warden::JWTAuth::UserEncoder)
          .to receive_message_chain(:new, :call)
          .and_return(["mock_token", { "jti" => "test-jti" }])
        post :acs_callback, params: { SAMLResponse: invite_saml_response }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"])
          .to include("https://#{ENV['UI_HOST']}/sso-sign-in?token=mock_token&success=true")
      end
    end

    context "when SAML response is missing" do
      it "returns an unauthorized error" do
        post :acs_callback, params: { SAMLResponse: invalid_saml_response }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to include("https://#{ENV['UI_HOST']}/sso-sign-in?success=false")
      end
    end

    context "when email is missing in the SAML response" do
      let(:saml_response_without_email) do
        Base64.encode64(
          <<~XML
            <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
              <saml:Issuer>https://login.microsoftonline.com</saml:Issuer>
              <saml:AttributeStatement>
                <saml:Attribute Name="some_other_attribute">
                </saml:Attribute>
              </saml:AttributeStatement>
            </saml:Assertion>
          XML
        )
      end

      it "returns an unauthorized error" do
        post :acs_callback, params: { SAMLResponse: saml_response_without_email }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to include("https://#{ENV['UI_HOST']}/sso-sign-in?success=false")
      end
    end

    context "when user is not found" do
      let(:unknown_email_saml_response) do
        Base64.encode64(
          <<~XML
            <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
              <saml:Issuer>https://login.microsoftonline.com</saml:Issuer>
              <saml:AttributeStatement>
                <saml:Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
                  <saml:AttributeValue>nil</saml:AttributeValue>
                </saml:Attribute>
              </saml:AttributeStatement>
            </saml:Assertion>
          XML
        )
      end

      it "returns an unauthorized error" do
        post :acs_callback, params: { SAMLResponse: unknown_email_saml_response }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to include("https://#{ENV['UI_HOST']}/sso-sign-in?success=false")
      end
    end

    context "when SAML response signature is invalid" do
      it "returns an unauthorized error" do
        allow(OneLogin::RubySaml::Response).to receive(:new).and_return(invalid_one_login_response)
        post :acs_callback, params: { SAMLResponse: valid_saml_response }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to include("https://#{ENV['UI_HOST']}/sso-sign-in?success=false")
      end
    end
  end
end
