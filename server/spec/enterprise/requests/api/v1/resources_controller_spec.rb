# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::ResourcesController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:resource) { create(:resource) }

  describe "GET /enterprise/api/v1/resources" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch all resources " do
        request.headers.merge!(auth_headers(user))
        get :index
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(1)
        expect(response_hash.dig(:data, 0, :attributes, :resources_name)).to eql(resource.resources_name)
        expect(response_hash.dig(:data, 0, :attributes, :permissions)).to eql(resource.permissions)
      end
    end
  end
end
