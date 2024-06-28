# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ReportsController", type: :request do
  let!(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let!(:user) { workspace.workspace_users.first.user }
  let!(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
    ]
  end
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

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
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: "failed", source: connectors.second,
                        destination: connectors.first),
      create(:sync_run, workspace:, model:, sync:,
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: nil, source: connectors.second,
                        destination: connectors.first),
      create(:sync_run, workspace:, model:, sync:,
                        total_rows: 2, successful_rows: 1, failed_rows: 1, error: nil, source: connectors.second,
                        destination: connectors.first)
    ]
  end

  describe "GET /api/v1/reports" do
    let(:slice_size) { Reports::ActivityReport::SLICE_SIZE }
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/reports"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and time slices for admin role" do
        get "/api/v1/reports?type=workspace_activity&connector_ids[]=#{connectors.first.id}",
            headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access[:data]
        expect(response_hash).to include(
          sync_run_triggered: a_kind_of(Array),
          total_sync_run_rows: a_kind_of(Array)
        )
        sync_run_triggered = response_hash.with_indifferent_access[:sync_run_triggered]
        expect(sync_run_triggered.count).to eq(slice_size)
        expect(sync_run_triggered[slice_size - 1]["time_slice"]).not_to be_nil
        expect(sync_run_triggered[slice_size - 1]["total_count"]).to eq(3)
        expect(sync_run_triggered[slice_size - 1]["success_count"]).to eq(2)
        expect(sync_run_triggered[slice_size - 1]["failed_count"]).to eq(1)

        total_sync_run_rows = response_hash.with_indifferent_access[:total_sync_run_rows]
        expect(total_sync_run_rows.count).to eq(slice_size)
        expect(total_sync_run_rows[slice_size - 1]["time_slice"]).not_to be_nil
        expect(total_sync_run_rows[slice_size - 1]["total_count"]).to eq(6)
        expect(total_sync_run_rows[slice_size - 1]["success_count"]).to eq(3)
        expect(total_sync_run_rows[slice_size - 1]["failed_count"]).to eq(3)
      end

      it "returns success and time slices for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/reports?type=workspace_activity&connector_ids[]=#{connectors.first.id}",
            headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access[:data]
        expect(response_hash).to include(
          sync_run_triggered: a_kind_of(Array),
          total_sync_run_rows: a_kind_of(Array)
        )
        sync_run_triggered = response_hash.with_indifferent_access[:sync_run_triggered]
        expect(sync_run_triggered.count).to eq(slice_size)
        expect(sync_run_triggered[slice_size - 1]["time_slice"]).not_to be_nil
        expect(sync_run_triggered[slice_size - 1]["total_count"]).to eq(3)
        expect(sync_run_triggered[slice_size - 1]["success_count"]).to eq(2)
        expect(sync_run_triggered[slice_size - 1]["failed_count"]).to eq(1)

        total_sync_run_rows = response_hash.with_indifferent_access[:total_sync_run_rows]
        expect(total_sync_run_rows.count).to eq(slice_size)
        expect(total_sync_run_rows[slice_size - 1]["time_slice"]).not_to be_nil
        expect(total_sync_run_rows[slice_size - 1]["total_count"]).to eq(6)
        expect(total_sync_run_rows[slice_size - 1]["success_count"]).to eq(3)
        expect(total_sync_run_rows[slice_size - 1]["failed_count"]).to eq(3)
      end

      it "returns success and time slices for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/reports?type=workspace_activity&connector_ids[]=#{connectors.first.id}",
            headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access[:data]
        expect(response_hash).to include(
          sync_run_triggered: a_kind_of(Array),
          total_sync_run_rows: a_kind_of(Array)
        )
        sync_run_triggered = response_hash.with_indifferent_access[:sync_run_triggered]
        expect(sync_run_triggered.count).to eq(slice_size)
        expect(sync_run_triggered[slice_size - 1]["time_slice"]).not_to be_nil
        expect(sync_run_triggered[slice_size - 1]["total_count"]).to eq(3)
        expect(sync_run_triggered[slice_size - 1]["success_count"]).to eq(2)
        expect(sync_run_triggered[slice_size - 1]["failed_count"]).to eq(1)

        total_sync_run_rows = response_hash.with_indifferent_access[:total_sync_run_rows]
        expect(total_sync_run_rows.count).to eq(slice_size)
        expect(total_sync_run_rows[slice_size - 1]["time_slice"]).not_to be_nil
        expect(total_sync_run_rows[slice_size - 1]["total_count"]).to eq(6)
        expect(total_sync_run_rows[slice_size - 1]["success_count"]).to eq(3)
        expect(total_sync_run_rows[slice_size - 1]["failed_count"]).to eq(3)
      end
    end
  end
end
