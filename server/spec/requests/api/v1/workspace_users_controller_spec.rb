# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::WorkspaceUsersController", type: :request do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }

  describe "GET /api/v1/workspaces/:workspace_id/workspace_users" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/workspaces/#{workspace.id}/workspace_users"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns a list of workspace users" do
        get "/api/v1/workspaces/#{workspace.id}/workspace_users",
            headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eq(workspace.workspace_users.count)
        expect(response_hash[:data].first[:type]).to eq("workspace_users")
        expect(response_hash[:data].first[:attributes][:role]).to eq(workspace.workspace_users.first.role)
      end
    end
  end
end
