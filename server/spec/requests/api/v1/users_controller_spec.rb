# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }

  describe "GET /api/v1/users/me" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/users/me"
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns user details" do
        user.update(created_at: "2024-05-16 15:02:36Z")
        get "/api/v1/users/me", headers: auth_headers(user)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :attributes, :name)).to eq(user.name)
        expect(response_hash.dig(:data, :attributes, :email)).to eq(user.email)
        expect(response_hash.dig(:data, :type)).to eq("users")
        expect(response_hash.dig(:data, :attributes, :created_at)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :role)).to eq(nil)
      end
    end
  end
end
