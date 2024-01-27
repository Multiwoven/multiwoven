# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ConnectorsController", type: :request do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
    ]
  end

  describe "GET /api/v1/connectors" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connectors"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and all connectors " do
        get "/api/v1/connectors", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count)
      end

      it "returns success and all source connectors" do
        get "/api/v1/connectors?type=source", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("source")
      end

      it "returns success and destination connectors" do
        get "/api/v1/connectors?type=destination", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("destination")
      end
    end
  end
end
