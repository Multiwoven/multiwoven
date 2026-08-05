# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::EmbedOriginsController, type: :controller do
  # Some code paths in dev+test try to reach the EC2 IMDS endpoint
  # (169.254.169.254) for AWS credential discovery. WebMock strict mode blocks
  # that; stub the probe so specs stay offline regardless of when the SDK
  # instantiates its credential chain.
  before do
    stub_request(:put,  "http://169.254.169.254/latest/api/token").to_return(status: 404)
    stub_request(:get,  %r{\Ahttp://169\.254\.169\.254/}).to_return(status: 404)
  end

  let(:workspace)     { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:organization)  { workspace.organization }
  let(:user)          { workspace.workspace_users.first.user }
  let!(:member_role)  { create(:role, role_name: "Member") }
  let!(:viewer_role)  { create(:role, role_name: "Viewer") }

  before do
    user.update!(confirmed_at: Time.current)
  end

  describe "GET #index" do
    context "when unauthenticated" do
      it "returns unauthorized" do
        get :index, params: { scope: "workspace" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when a Viewer" do
      it "allows read via workspace scope" do
        workspace.workspace_users.first.update!(role: create(:role, :viewer))
        create(:user_embed_origin,
               created_by_user: user, origin: "https://ws.com",
               organization:, workspace:)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index, params: { scope: "workspace" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).map { |r| r["origin"] }).to include("https://ws.com")
      end
    end

    context "when a Member with default (empty) permissions" do
      it "returns forbidden" do
        workspace.workspace_users.first.update!(role: member_role)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index, params: { scope: "workspace" }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when scope is invalid" do
      it "returns bad request" do
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index, params: { scope: "not_a_scope" }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when scope is organization" do
      it "returns only rows where workspace_id IS NULL" do
        create(:user_embed_origin,
               created_by_user: user, origin: "https://ws.com",
               organization:, workspace:)
        create(:user_embed_origin,
               created_by_user: user, origin: "https://org.com",
               organization:, workspace: nil)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index, params: { scope: "organization" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).map { |r| r["origin"] }).to contain_exactly("https://org.com")
      end
    end

    context "when scope is workspace" do
      it "returns only rows for the current workspace (excluding other workspaces and org-wide)" do
        create(:user_embed_origin,
               created_by_user: user, origin: "https://ws.com",
               organization:, workspace:)
        create(:user_embed_origin,
               created_by_user: user, origin: "https://org.com",
               organization:, workspace: nil)
        other_ws = create(:workspace, organization:)
        create(:user_embed_origin,
               created_by_user: user, origin: "https://other.com",
               organization:, workspace: other_ws)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index, params: { scope: "workspace" }
        expect(JSON.parse(response.body).map { |r| r["origin"] }).to contain_exactly("https://ws.com")
      end
    end

    context "when scope is omitted" do
      it "returns every row in the organization" do
        create(:user_embed_origin,
               created_by_user: user, origin: "https://ws.com",
               organization:, workspace:)
        create(:user_embed_origin,
               created_by_user: user, origin: "https://org.com",
               organization:, workspace: nil)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).map { |r| r["origin"] }).to contain_exactly("https://ws.com", "https://org.com")
      end
    end
  end

  describe "POST #create" do
    before { request.headers.merge!(auth_headers(user, workspace_id)) }

    it "creates a workspace-scoped origin" do
      expect do
        post :create, params: { origin: "https://customer.com", scope: "workspace" }
      end.to change(UserEmbedOrigin, :count).by(1)

      expect(response).to have_http_status(:created)
      record = UserEmbedOrigin.last
      expect(record.workspace_id).to eq(workspace.id)
      expect(record.organization_id).to eq(organization.id)
      expect(record.created_by_id).to eq(user.id)
    end

    it "returns propagation meta on the response" do
      post :create, params: { origin: "https://customer.com", scope: "workspace" }
      body = JSON.parse(response.body)
      expect(body["meta"]).to include(
        "refresh_interval_seconds" => EmbedOrigins::Registry::REFRESH_INTERVAL_SECONDS
      )
      expect(body["meta"]["message"]).to be_present
    end

    it "creates an org-wide origin (workspace_id nil)" do
      post :create, params: { origin: "https://ai.squared.ai", scope: "organization" }
      expect(response).to have_http_status(:created)
      expect(UserEmbedOrigin.last.workspace_id).to be_nil
    end

    it "returns 422 for an invalid origin" do
      post :create, params: { origin: "not a url", scope: "workspace" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 400 when scope is missing/unknown" do
      post :create, params: { origin: "https://customer.com" }
      expect(response).to have_http_status(:bad_request)
    end

    it "forbids Member role" do
      workspace.workspace_users.first.update!(role: member_role)
      post :create, params: { origin: "https://customer.com", scope: "workspace" }
      expect(response).to have_http_status(:forbidden)
    end

    it "rejects a workspace-scoped origin already listed org-wide" do
      create(:user_embed_origin,
             created_by_user: user, organization:, workspace: nil,
             origin: "https://shadowed.com")
      post :create, params: { origin: "https://shadowed.com", scope: "workspace" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "allows promoting a workspace-scoped origin to org-wide" do
      create(:user_embed_origin,
             created_by_user: user, organization:, workspace:,
             origin: "https://promote.com")
      post :create, params: { origin: "https://promote.com", scope: "organization" }
      expect(response).to have_http_status(:created)
    end

    it "returns 422 (not 500) when the same user posts a duplicate workspace-scoped origin" do
      create(:user_embed_origin,
             created_by_user: user, organization:, workspace:,
             origin: "https://dup.com")
      post :create, params: { origin: "https://dup.com", scope: "workspace" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 (not 500) when the same user posts a duplicate org-wide origin" do
      create(:user_embed_origin,
             created_by_user: user, organization:, workspace: nil,
             origin: "https://dup-org.com")
      post :create, params: { origin: "https://dup-org.com", scope: "organization" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT #update" do
    let!(:record) do
      create(:user_embed_origin, created_by_user: user, organization:, workspace:)
    end

    before { request.headers.merge!(auth_headers(user, workspace_id)) }

    it "updates the origin" do
      put :update, params: { id: record.id, origin: "https://updated.com" }
      expect(response).to have_http_status(:ok)
      expect(record.reload.origin).to eq("https://updated.com")
      body = JSON.parse(response.body)
      expect(body["meta"]).to include(
        "refresh_interval_seconds" => EmbedOrigins::Registry::REFRESH_INTERVAL_SECONDS
      )
      expect(body["meta"]["message"]).to be_present
    end

    it "returns 422 for an invalid origin" do
      put :update, params: { id: record.id, origin: "not a url" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 404 for an unknown id" do
      put :update, params: { id: 999_999, origin: "https://x.com" }
      expect(response).to have_http_status(:not_found)
    end

    it "forbids Viewer role" do
      workspace.workspace_users.first.update!(role: create(:role, :viewer))
      put :update, params: { id: record.id, origin: "https://updated.com" }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 (not 500) when renaming to an origin the user already has" do
      create(:user_embed_origin,
             created_by_user: user, organization:, workspace:,
             origin: "https://taken.com")
      put :update, params: { id: record.id, origin: "https://taken.com" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE #destroy" do
    let!(:record) do
      create(:user_embed_origin, created_by_user: user, organization:, workspace:)
    end

    before { request.headers.merge!(auth_headers(user, workspace_id)) }

    it "removes the record" do
      expect { delete :destroy, params: { id: record.id } }.to change(UserEmbedOrigin, :count).by(-1)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["meta"]).to include(
        "refresh_interval_seconds" => EmbedOrigins::Registry::REFRESH_INTERVAL_SECONDS
      )
      expect(body["meta"]["message"]).to be_present
    end

    it "returns 404 for an unknown id" do
      delete :destroy, params: { id: 999_999 }
      expect(response).to have_http_status(:not_found)
    end

    it "does not find records from other organizations" do
      foreign = create(:user_embed_origin)
      delete :destroy, params: { id: foreign.id }
      expect(response).to have_http_status(:not_found)
      expect(UserEmbedOrigin.exists?(foreign.id)).to be(true)
    end

    it "forbids Viewer role" do
      workspace.workspace_users.first.update!(role: create(:role, :viewer))
      delete :destroy, params: { id: record.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #lookup" do
    let!(:data_app) { create(:data_app, workspace:) }

    before do
      create(:user_embed_origin,
             created_by_user: user, origin: "https://customer.com",
             organization:, workspace:)
      EmbedOrigins::Registry.refresh!
    end

    it "returns the workspace's allowed origins for a data-app in the Registry" do
      get :lookup, params: { data_app_id: data_app.id }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["origins"]).to include("https://customer.com")
      expect(body["meta"]["refresh_interval_seconds"])
        .to eq(EmbedOrigins::Registry::REFRESH_INTERVAL_SECONDS)
    end

    it "returns an empty origins list for an unknown data_app_id" do
      get :lookup, params: { data_app_id: 999_999 }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["origins"]).to eq([])
    end

    it "returns an empty origins list for a draft data-app not in the Registry" do
      draft = create(:data_app, workspace:, status: :draft)
      EmbedOrigins::Registry.refresh!

      get :lookup, params: { data_app_id: draft.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["origins"]).to eq([])
    end

    it "returns 400 when data_app_id is missing" do
      get :lookup
      expect(response).to have_http_status(:bad_request)
    end

    it "is reachable without an authenticated user (embed runtime is anonymous)" do
      # No auth_headers merged — contrast with the :unauthenticated context on
      # GET #index above which returns 401 for the same absence of a token.
      get :lookup, params: { data_app_id: data_app.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["origins"]).to include("https://customer.com")
    end
  end
end
