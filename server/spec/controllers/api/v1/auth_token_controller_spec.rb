# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::AuthTokenController, type: :controller do
  let(:user) { create(:user, confirmed_at: Time.current) }

  # Appsignal (loaded via APPSIGNAL_PUSH_API_KEY in the dev/test .env) probes
  # cloud-provider metadata endpoints on first use to identify the host.
  # WebMock blocks those and the failure noise obscures real assertions.
  # Stub every common metadata endpoint so the probe returns silently.
  before do
    # AWS IMDSv1 + IMDSv2 (also matches Azure IMDS, which uses the same IP).
    stub_request(:any, %r{http://169\.254\.169\.254/})
      .to_return(status: 404, body: "", headers: {})
    # GCP metadata server.
    stub_request(:any, %r{http://metadata\.google\.internal/})
      .to_return(status: 404, body: "", headers: {})
    # Azure IMDS (alt hostname).
    stub_request(:any, %r{http://metadata\.azure\.com/})
      .to_return(status: 404, body: "", headers: {})

    allow(Utils::ExceptionReporter).to receive(:report)
  end

  def issue_token_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.update!(jti: payload["jti"])
    token
  end

  describe "GET #show" do
    context "without any credential" do
      it "returns 401 unauthorized" do
        get :show
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with the JWT in the Authorization header" do
      it "returns 200 with the token echoed back" do
        token = issue_token_for(user)
        request.headers["Authorization"] = "Bearer #{token}"

        get :show

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["token"]).to eq(token)
      end
    end

    context "with the JWT in the auth cookie" do
      it "returns 200 with the token echoed back" do
        token = issue_token_for(user)
        request.cookies[AuthCookies::AUTH_COOKIE_NAME] = token

        get :show

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["token"]).to eq(token)
      end
    end

    context "with an invalid JWT in the header" do
      it "returns 401 when the JWT can't be decoded" do
        request.headers["Authorization"] = "Bearer not-a-real-jwt"

        get :show

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
