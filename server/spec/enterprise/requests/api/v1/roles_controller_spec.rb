# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::RolesController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }

  describe "GET /enterprise/api/v1/roles" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch all roles" do
        request.headers.merge!(auth_headers(user))
        get :index
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(1)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :role_name)).to eql(workspace.workspace_users.first.role.role_name)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :role_desc)).to eql(workspace.workspace_users.first.role.role_desc)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :policies)).to eql(workspace.workspace_users.first.role.policies)
      end
    end
  end
end
