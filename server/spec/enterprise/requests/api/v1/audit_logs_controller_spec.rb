# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::AuditLogsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let!(:audit_logs) do
    [
      create(:audit_log, created_at: 2.days.ago, updated_at: 2.days.ago, workspace:, user:),
      create(:audit_log, workspace:, user:),
      create(:audit_log, created_at: 1.day.ago, updated_at: 1.day.ago, workspace:, user:)
    ]
  end
  let(:mock_params) do
    {
      start_date: (Time.current - 2.days).strftime("%Y-%m-%d"),
      end_date: (Time.current + 1.day).strftime("%Y-%m-%d"),
      user_id: audit_logs.first.user_id,
      resource_type: audit_logs.first.resource_type,
      resource: audit_logs.first.resource,
      page: 1
    }
  end
  let(:member_role) { create(:role, :member) }

  before do
    user.update!(confirmed_at: Time.current)
  end

  describe "GET /enterprise/api/v1/audit_logs" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch all audit log" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
        get :index, params: mock_params
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        first_row_date = response_hash["data"].first["attributes"]["created_at"]
        last_row_date = response_hash["data"].last["attributes"]["created_at"]
        expect(first_row_date).to be > last_row_date

        expect(response_hash["data"].size).to eq(3)
        expect(response_hash["data"].first["id"]).to eql(audit_logs.second.id.to_s)
        expect(response_hash["data"].first["attributes"]["user_id"]).to eql(audit_logs.second.user_id)
        expect(response_hash["data"].first["attributes"]["user_name"]).to eql(user.name)
        expect(response_hash["data"].first["attributes"]["action"]).to eql(audit_logs.second.action)
        expect(response_hash["data"].first["attributes"]["resource_type"]).to eql(audit_logs.second.resource_type)
        expect(response_hash["data"].first["attributes"]["resource_id"]).to eql(audit_logs.second.resource_id)
        expect(response_hash["data"].first["attributes"]["resource"]).to eql(audit_logs.second.resource)
        expect(response_hash["data"].first["attributes"]["workspace_id"]).to eql(workspace_id)
        expect(response_hash["data"].first["attributes"]["metadata"]).to eql(audit_logs.second.metadata)
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/audit_logs?")
        expect(response_hash.dig(:links, :first))
          .to include("page=1&per_page=10")
      end
    end
  end
end
