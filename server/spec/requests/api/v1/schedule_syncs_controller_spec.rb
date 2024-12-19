# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ScheduleSyncsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:new_role) { create(:role, :viewer) }
  let(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift"),
      create(:connector, workspace:, connector_type: "destination", name: "klavio2", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift2", connector_name: "Redshift")
    ]
  end

  before do
    user.confirm
    create(:catalog, connector: connectors.find { |connector| connector.name == "klavio1" }, workspace:)
    create(:catalog, connector: connectors.find { |connector| connector.name == "redshift" }, workspace:)
  end

  let(:model) do
    create(:model, connector: connectors.second, workspace:, name: "model1", query: "SELECT * FROM locations")
  end

  let(:sync) do
    create(:sync, workspace:, model:, source: connectors.second, destination: connectors.first, schedule_type: "manual")
  end

  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  let(:request_body) do
    {
      schedule_sync: {
        sync_id: sync.id
      }
    }
  end

  describe "POST /api/v1/syncs - Create sync" do
    before do
      allow(Temporal).to receive(:start_workflow).and_return(true)
    end

    context "when we schedule a manual sync with valid sync_id" do
      it "creates a new sync and returns success" do
        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        expect(Temporal).to have_received(:start_workflow).with(
          Workflows::SyncWorkflow,
          sync.id,
          { options: { workflow_id: "redshift-klaviyo-syncid-#{sync.id}" } }
        )
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "message" => "Sync scheduled successfully" })

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Schedule_sync")
        expect(audit_log.resource_id).to eq(request_body[:schedule_sync][:sync_id])
        expect(audit_log.resource).to eq(request_body.dig(:sync, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/activate/syncs/#{request_body[:schedule_sync][:sync_id]}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "when sync id is incorrect" do
      it "returns failure" do
        error_message = "Sync not found"
        request_body[:schedule_sync][:sync_id] = 514_254

        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(404)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end

    context "when sync id is correct but has an active sync_run" do
      it "returns failure" do
        error_message = "Sync cannot be scheduled due to active sync run"
        create(:sync_run, sync:, workspace:, total_rows: 3, successful_rows: 2, failed_rows: 1, error: "failed",
                          source: connectors.second, destination: connectors.first, status: "querying")
        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(424)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end

    context "when sync id is correct but has an invalid schedule type" do
      it "returns failure" do
        sync.update(schedule_type: "interval")
        error_message = "Sync Schedule type should be manual"
        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(424)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end

    context "when sync id is correct but it is disabled" do
      it "returns failure" do
        sync.update(status: "disabled")
        error_message = "Sync is disabled"
        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(424)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end
  end

  describe "DELETE /api/v1/syncs/id" do
    before do
      create(:sync_run, sync:, workspace:, total_rows: 3, successful_rows: 2, failed_rows: 1, error: "failed",
                        source: connectors.second, destination: connectors.first, status: "querying")
      allow(Temporal).to receive(:start_workflow).and_return(true)
    end

    context "when we pass valid sync id and workflow id" do
      it "returns success and delete sync runs" do
        sync.update(workflow_id: "redshift-klaviyo-syncid-#{sync.id}")
        delete "/api/v1/schedule_syncs/#{sync.id}", headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        expect(Temporal).to have_received(:start_workflow).with(
          Workflows::TerminateWorkflow,
          "redshift-klaviyo-syncid-#{sync.id}",
          { options: { workflow_id: "terminate-redshift-klaviyo-syncid-#{sync.id}" } }
        )

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "message" => "Sync cancelled successfully" })
        expect(sync.sync_runs.last.status).to eq("canceled")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Schedule_sync")
        expect(audit_log.resource_id).to eq(request_body[:schedule_sync][:sync_id])
        expect(audit_log.resource).to eq(request_body.dig(:sync, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "when we pass invalid sync id" do
      it "returns failure" do
        error_message = "Sync not found"
        delete "/api/v1/schedule_syncs/1_232_131", headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(404)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end

    context "when sync id is correct but has inactive sync_run" do
      it "returns failure" do
        error_message = "Sync cannot be scheduled due to active sync run"
        post "/api/v1/schedule_syncs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(424)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end
  end
end
