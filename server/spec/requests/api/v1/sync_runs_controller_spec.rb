# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::SyncRunsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:source) do
    create(:connector, workspace:, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, workspace:, connector_type: "destination") }
  let!(:catalog) { create(:catalog, workspace:, connector: destination) }
  let!(:sync) { create(:sync, source:, workspace:, destination:) }

  let!(:sync_runs) do
    [
      create(:sync_run, sync:, workspace:, total_rows: 3, successful_rows: 2, failed_rows: 1, error: "failed", source:,
                        destination:, status: "failed"),
      create(:sync_run, sync:, workspace:, total_rows: 1, successful_rows: 1, failed_rows: 0, error: nil, source:,
                        destination:, status: "success")
    ]
  end
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    user.confirm
  end

  describe "GET /api/v1/syncs/sync_id/sync_runs" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/syncs/#{sync.id}/sync_runs"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch sync " do
        get "/api/v1/syncs/#{sync.id}/sync_runs?page=1&per_page=20", headers: auth_headers(user, workspace_id)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response).to have_http_status(:ok)
        expect(response_hash[:data].size).to eq(2)
        first_row_date = DateTime.parse(response_hash[:data].first.dig(:attributes, :updated_at))
        second_row_date = DateTime.parse(response_hash[:data].last.dig(:attributes, :updated_at))
        expect(first_row_date).to be > second_row_date
        response_hash[:data].each_with_index do |row, _index|
          sync_run = sync_runs.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_run.id.to_s)
          expect(row[:type]).to eq("sync_runs")
          expect(row.dig(:attributes, :total_rows)).to eq(sync_run.total_rows)
          expect(row.dig(:attributes, :successful_rows)).to eq(sync_run.successful_rows)
          expect(row.dig(:attributes, :failed_rows)).to eq(sync_run.failed_rows)
          expect(row.dig(:attributes, :status)).to eq(sync_run.status)
          expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs?page=1&per_page=20")
        end
      end

      it "returns success and fetch sync for member_role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)
        response_hash[:data].each_with_index do |row, _index|
          sync_run = sync_runs.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_run.id.to_s)
          expect(row[:type]).to eq("sync_runs")
          expect(row.dig(:attributes, :total_rows)).to eq(sync_run.total_rows)
          expect(row.dig(:attributes, :successful_rows)).to eq(sync_run.successful_rows)
          expect(row.dig(:attributes, :failed_rows)).to eq(sync_run.failed_rows)
          expect(row.dig(:attributes, :status)).to eq(sync_run.status)
          expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs?page=1")
        end
      end

      it "returns success and fetch sync for viewer_role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)
        response_hash[:data].each_with_index do |row, _index|
          sync_run = sync_runs.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_run.id.to_s)
          expect(row[:type]).to eq("sync_runs")
          expect(row.dig(:attributes, :total_rows)).to eq(sync_run.total_rows)
          expect(row.dig(:attributes, :successful_rows)).to eq(sync_run.successful_rows)
          expect(row.dig(:attributes, :failed_rows)).to eq(sync_run.failed_rows)
          expect(row.dig(:attributes, :status)).to eq(sync_run.status)
          expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs?page=1")
        end
      end
    end

    context "when it is an authenticated user and passing invalid parameters" do
      it "returns an error and does not fetch sync runs for invalid status" do
        get "/api/v1/syncs/#{sync.id}/sync_runs?status=invalid", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("must be a valid status")
      end

      it "returns an error and does not fetch sync runs for invalid page" do
        get "/api/v1/syncs/#{sync.id}/sync_runs?page=oi", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("must be an integer")
      end

      it "returns an error and does not fetch sync runs for invalid sync id" do
        get "/api/v1/syncs/10099/sync_runs", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Sync not found")
      end
    end
  end

  describe "GET /api/v1/syncs/sync_id/sync_runs/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_runs.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch sync for member_role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_runs.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        expect(response_hash.dig(:data, :id)).to eq(sync_runs.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("sync_runs")
        expect(response_hash.dig(:data, :attributes, :total_rows)).to eq(sync_runs.first.total_rows)
        expect(response_hash.dig(:data, :attributes, :successful_rows)).to eq(sync_runs.first.successful_rows)
        expect(response_hash.dig(:data, :attributes, :failed_rows)).to eq(sync_runs.first.failed_rows)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(sync_runs.first.status)
      end

      it "returns success and fetch sync for " do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_runs.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        expect(response_hash.dig(:data, :id)).to eq(sync_runs.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("sync_runs")
        expect(response_hash.dig(:data, :attributes, :total_rows)).to eq(sync_runs.first.total_rows)
        expect(response_hash.dig(:data, :attributes, :successful_rows)).to eq(sync_runs.first.successful_rows)
        expect(response_hash.dig(:data, :attributes, :failed_rows)).to eq(sync_runs.first.failed_rows)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(sync_runs.first.status)
      end

      it "returns success and fetch sync " do
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_runs.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        expect(response_hash.dig(:data, :id)).to eq(sync_runs.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("sync_runs")
        expect(response_hash.dig(:data, :attributes, :total_rows)).to eq(sync_runs.first.total_rows)
        expect(response_hash.dig(:data, :attributes, :successful_rows)).to eq(sync_runs.first.successful_rows)
        expect(response_hash.dig(:data, :attributes, :failed_rows)).to eq(sync_runs.first.failed_rows)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(sync_runs.first.status)
      end
    end

    context "when it is an authenticated user and passing invalid parameters" do
      it "returns an error and does not fetch sync runs for invalid id" do
        get "/api/v1/syncs/#{sync.id}/sync_runs/invalid", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("must be an integer")
      end

      it "returns an error and does not fetch sync run notfound" do
        get "/api/v1/syncs/#{sync.id}/sync_runs/23546436", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Sync Run not found")
      end

      it "returns an error and does not fetch sync runs for invalid sync id" do
        get "/api/v1/syncs/10099/sync_runs", headers: auth_headers(user, workspace_id)

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Sync not found")
      end
    end
  end
end
