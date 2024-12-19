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

  let!(:sync_run) do
    create(:sync_run, sync:, workspace:, total_rows: 3, successful_rows: 2, failed_rows: 1,
                      error: "failed", source:, destination:, status: "success")
  end
  let!(:sync_records) do
    [
      create(:sync_record, sync:, sync_run:, status: "success", primary_key: "key1"),
      create(:sync_record, sync:, sync_run:, status: "failed", primary_key: "key2", logs: { message: "test" })
    ]
  end
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    user.confirm
  end

  describe "GET /api/v1/syncs/sync_id/sync_runs/sync_run_id/sync_records" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch sync " do
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?page=1&per_page=20",
            headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)
        first_row_date = DateTime.parse(response_hash[:data].first.dig(:attributes, :created_at))
        second_row_date = DateTime.parse(response_hash[:data].last.dig(:attributes, :created_at))
        expect(second_row_date).to be > first_row_date
        response_hash[:data].each_with_index do |row, _index|
          sync_record = sync_records.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_record.id.to_s)
          expect(row[:type]).to eq("sync_records")
          expect(row.dig(:attributes, :sync_id)).to eq(sync_record.sync_id)
          expect(row.dig(:attributes, :sync_run_id)).to eq(sync_record.sync_run_id)
          expect(row.dig(:attributes, :record)).to eq(sync_record.record)
          expect(row.dig(:attributes, :action)).to eq(sync_record.action)
          expect(row.dig(:attributes, :status)).to eq(sync_record.status)
          if sync_record.status == "failed"
            expect(row.dig(:attributes, :logs)).to eq(sync_record.logs)
            expect { JSON.parse(row.dig(:attributes, :logs).to_json) }.not_to raise_error
          end
          expect(response_hash.dig(:links, :first))
            .to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?page=1&per_page=20")
        end
      end

      it "returns success and fetch sync for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)

        response_hash[:data].each_with_index do |row, _index|
          sync_record = sync_records.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_record.id.to_s)
          expect(row[:type]).to eq("sync_records")
          expect(row.dig(:attributes, :sync_id)).to eq(sync_record.sync_id)
          expect(row.dig(:attributes, :sync_run_id)).to eq(sync_record.sync_run_id)
          expect(row.dig(:attributes, :record)).to eq(sync_record.record)
          expect(row.dig(:attributes, :action)).to eq(sync_record.action)
          expect(row.dig(:attributes, :status)).to eq(sync_record.status)
          if sync_record.status == "failed"
            expect(row.dig(:attributes, :logs)).to eq(sync_record.logs)
            expect { JSON.parse(row.dig(:attributes, :logs).to_json) }.not_to raise_error
          end
          expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?page=1")
        end
      end

      it "returns success and fetch sync for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)

        response_hash[:data].each_with_index do |row, _index|
          sync_record = sync_records.find { |sr| sr.id == row[:id].to_i }

          expect(row[:id]).to eq(sync_record.id.to_s)
          expect(row[:type]).to eq("sync_records")
          expect(row.dig(:attributes, :sync_id)).to eq(sync_record.sync_id)
          expect(row.dig(:attributes, :sync_run_id)).to eq(sync_record.sync_run_id)
          expect(row.dig(:attributes, :record)).to eq(sync_record.record)
          expect(row.dig(:attributes, :action)).to eq(sync_record.action)
          expect(row.dig(:attributes, :status)).to eq(sync_record.status)
          if sync_record.status == "failed"
            expect(row.dig(:attributes, :logs)).to eq(sync_record.logs)
            expect { JSON.parse(row.dig(:attributes, :logs).to_json) }.not_to raise_error
          end
          expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?page=1")
        end
      end

      context "when it is an authenticated user and passing invalid parameters" do
        it "returns an error and does not fetch sync records for invalid status" do
          get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?status=invalid",
              headers: auth_headers(user, workspace_id)

          expect(response).to have_http_status(:bad_request)
          expect(response.body).to include("must be a valid status")
        end

        it "returns an error and does not fetch sync records for invalid page" do
          get "/api/v1/syncs/#{sync.id}/sync_runs/#{sync_run.id}/sync_records?page=oi",
              headers: auth_headers(user, workspace_id)

          expect(response).to have_http_status(:bad_request)
          expect(response.body).to include("must be an integer")
        end

        it "returns an error and does not fetch sync records for invalid sync id" do
          get "/api/v1/syncs/1979697/sync_runs/#{sync_run.id}/sync_records", headers: auth_headers(user, workspace_id)

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include("Sync not found")
        end

        it "returns an error and does not fetch sync records for invalid sync run id" do
          get "/api/v1/syncs//#{sync.id}/sync_runs/9798787/sync_records", headers: auth_headers(user, workspace_id)

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include("SyncRun not found")
        end
      end
    end
  end
end
