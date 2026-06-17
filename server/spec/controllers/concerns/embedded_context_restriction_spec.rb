# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddedContextRestriction, type: :controller do
  # Create a test controller that includes the concern
  controller(ApplicationController) do
    def index
      render json: { message: "success" }, status: :ok
    end

    def show
      render json: { message: "success" }, status: :ok
    end
  end

  let(:workspace) { create(:workspace) }
  let(:user) { workspace.users.first }
  let(:password) { "Password@123" }
  let(:confirmed_user) { create(:user, password:, password_confirmation: password, confirmed_at: Time.current) }

  before do
    routes.draw do
      get "index", to: "anonymous#index"
      get "show", to: "anonymous#show"
      namespace :enterprise do
        namespace :api do
          namespace :v1 do
            get "data_apps", to: "data_apps#index"
            get "data_apps/:id", to: "data_apps#show"
            post "data_apps/:id/fetch_data", to: "data_apps#fetch_data"
            get "data_app_sessions", to: "data_app_sessions#index"
            namespace :agents do
              get "workflows", to: "workflows#index"
              get "workflows/:id", to: "workflows#show"
              post "workflows/:id/run", to: "workflows#run"
            end
            get "users", to: "users#index" # Disallowed endpoint for testing
          end
        end
      end
    end
  end

  describe "#app_context_from_token" do
    context "when token has app_context 'embed'" do
      let(:token_with_context) do
        standard_token, _payload = Warden::JWTAuth::UserEncoder.new.call(confirmed_user, :user, nil)
        secret = Devise::JWT.config.secret
        decoded = JWT.decode(standard_token, secret, true, algorithm: "HS256")
        decoded[0]["app_context"] = "embed"
        JWT.encode(decoded[0], secret, "HS256")
      end

      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        request.headers["Authorization"] = "Bearer #{token_with_context}"
      end

      it "returns 'embed'" do
        expect(controller.send(:app_context_from_token)).to eq("embed")
      end
    end

    context "when token does not have app_context" do
      let(:standard_token) do
        token, _payload = Warden::JWTAuth::UserEncoder.new.call(confirmed_user, :user, nil)
        token
      end

      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        request.headers["Authorization"] = "Bearer #{standard_token}"
      end

      it "returns nil" do
        expect(controller.send(:app_context_from_token)).to be_nil
      end
    end

    context "when user is not signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end

      it "returns nil" do
        expect(controller.send(:app_context_from_token)).to be_nil
      end
    end

    context "when Authorization header is missing" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        request.headers["Authorization"] = nil
      end

      it "returns nil" do
        expect(controller.send(:app_context_from_token)).to be_nil
      end
    end

    context "when token is invalid" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
        request.headers["Authorization"] = "Bearer invalid_token"
      end

      it "returns nil" do
        expect(controller.send(:app_context_from_token)).to be_nil
      end
    end
  end

  describe "#embedded_context_token?" do
    context "when app_context is 'embed'" do
      before do
        allow(controller).to receive(:app_context_from_token).and_return("embed")
      end

      it "returns true" do
        expect(controller.send(:embedded_context_token?)).to be(true)
      end

      it "memoizes the result" do
        expect(controller).to receive(:app_context_from_token).once.and_return("embed")
        controller.send(:embedded_context_token?)
        controller.send(:embedded_context_token?)
      end
    end

    context "when app_context is not 'embed'" do
      before do
        allow(controller).to receive(:app_context_from_token).and_return(nil)
      end

      it "returns false" do
        expect(controller.send(:embedded_context_token?)).to be(false)
      end
    end
  end

  describe "#embedded_context_allowed?" do
    context "when controller and action match allowed endpoint" do
      before do
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/data_apps")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "returns true" do
        expect(controller.send(:embedded_context_allowed?)).to be(true)
      end
    end

    context "when controller matches but action does not" do
      before do
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/data_apps")
        allow(controller).to receive(:action_name).and_return("create")
      end

      it "returns false" do
        expect(controller.send(:embedded_context_allowed?)).to be(false)
      end
    end

    context "when controller allows all actions (action is nil)" do
      before do
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/data_app_sessions")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "returns true" do
        expect(controller.send(:embedded_context_allowed?)).to be(true)
      end
    end

    context "when controller does not match" do
      before do
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/users")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "returns false" do
        expect(controller.send(:embedded_context_allowed?)).to be(false)
      end
    end
  end

  describe "#restrict_embedded_context_apis" do
    let(:token_with_context) do
      standard_token, _payload = Warden::JWTAuth::UserEncoder.new.call(confirmed_user, :user, nil)
      secret = Devise::JWT.config.secret
      decoded = JWT.decode(standard_token, secret, true, algorithm: "HS256")
      decoded[0]["app_context"] = "embed"
      JWT.encode(decoded[0], secret, "HS256")
    end

    let(:standard_token) do
      token, _payload = Warden::JWTAuth::UserEncoder.new.call(confirmed_user, :user, nil)
      token
    end

    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:validate_contract) # Skip contract validation for test controller
      allow(controller).to receive(:authorize).and_return(true) # Skip authorization for test controller
      allow(controller).to receive(:verify_authorized) # Skip authorization verification
      allow(controller).to receive(:current_user).and_return(confirmed_user)
      allow(controller).to receive(:current_workspace).and_return(workspace)
      confirmed_user.update!(jti: SecureRandom.uuid)
    end

    context "when token has embedded context and endpoint is allowed" do
      before do
        request.headers["Authorization"] = "Bearer #{token_with_context}"
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/data_apps")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "allows the request" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context "when token has embedded context and endpoint is not allowed" do
      before do
        request.headers["Authorization"] = "Bearer #{token_with_context}"
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/users")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "returns forbidden" do
        get :index
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"][0]["detail"])
          .to eq("This API endpoint is not available for embedded context tokens")
      end
    end

    context "when token does not have embedded context" do
      before do
        request.headers["Authorization"] = "Bearer #{standard_token}"
        allow(controller).to receive(:controller_path).and_return("enterprise/api/v1/users")
        allow(controller).to receive(:action_name).and_return("index")
      end

      it "allows the request" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
        request.headers["Authorization"] = nil
      end

      it "allows the request (authentication will be handled separately)" do
        get :index
        # The request will fail authentication, but not due to embedded context restriction
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#embedded_context_allowed_endpoints" do
    it "returns the correct list of allowed endpoints" do
      endpoints = controller.send(:embedded_context_allowed_endpoints)

      expect(endpoints).to include(
        { controller: "enterprise/api/v1/data_app_sessions", action: nil },
        { controller: "enterprise/api/v1/data_apps", action: :index },
        { controller: "enterprise/api/v1/data_apps", action: :show },
        { controller: "enterprise/api/v1/data_apps", action: :fetch_data },
        { controller: "enterprise/api/v1/data_apps", action: :fetch_data_stream },
        { controller: "enterprise/api/v1/data_apps", action: :write_data },
        { controller: "enterprise/api/v1/agents/workflows", action: :index },
        { controller: "enterprise/api/v1/agents/workflows", action: :show },
        { controller: "enterprise/api/v1/agents/workflows", action: :run },
        { controller: "enterprise/api/v1/message_feedbacks", action: nil },
        { controller: "enterprise/api/v1/feedbacks", action: nil },
        { controller: "enterprise/api/v1/custom_visual_component", action: :show }
      )
    end
  end
end
