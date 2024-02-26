# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ReportsController", type: :request do
  let!(:workspace) { create(:workspace) }
  let!(:user) { workspace.workspace_users.first.user }
  let!(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
    ]
  end

  before do
    create(:catalog, connector: connectors.find { |connector| connector.name == "klavio1" }, workspace:)
    create(:catalog, connector: connectors.find { |connector| connector.name == "redshift" }, workspace:)
  end

  let!(:model) do
    create(:model, connector: connectors.second, workspace:, name: "model1", query: "SELECT * FROM locations")
  end

  let!(:sync) { create(:sync, workspace:, model:, source: connectors.second, destination: connectors.first) }

  let!(:sync_runs) do
    [
      create(:sync_run, workspace:, model:, sync:,
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: "failed"),
      create(:sync_run, workspace:, model:, sync:,
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: nil),
      create(:sync_run, workspace:, model:, sync:,
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: nil)
    ]
  end

  describe "GET /api/v1/reports" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/reports"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and time slices " do
        get "/api/v1/reports?type=workspace_activity", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access[:data]
        expect(response_hash).to include(
          sync_run_triggered: a_kind_of(Array),
          total_sync_run_rows: a_kind_of(Array)
        )
        sync_run_triggered = response_hash.with_indifferent_access[:sync_run_triggered]
        expect(sync_run_triggered.count).to eq(1)
        expect(sync_run_triggered[0]["time_slice"]).not_to be_nil
        expect(sync_run_triggered[0]["total_count"]).to eq(3)
        expect(sync_run_triggered[0]["success_count"]).to eq(2)
        expect(sync_run_triggered[0]["failed_count"]).to eq(1)

        total_sync_run_rows = response_hash.with_indifferent_access[:total_sync_run_rows]
        expect(total_sync_run_rows.count).to eq(1)
        expect(total_sync_run_rows[0]["time_slice"]).not_to be_nil
        expect(total_sync_run_rows[0]["total_count"]).to eq(6)
        expect(total_sync_run_rows[0]["success_count"]).to eq(3)
        expect(total_sync_run_rows[0]["failed_count"]).to eq(3)
      end
    end
  end
end
