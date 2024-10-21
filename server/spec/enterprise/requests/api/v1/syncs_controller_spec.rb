# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::SyncsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:new_role) { create(:role, :viewer) }
  let(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
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

  describe "POST /enterprise/api/v1/sync/id/test" do
    before do
      allow(Temporal).to receive(:start_workflow).and_return(true)
    end

    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        post :test, params: { id: sync.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when we schedule a manual sync with valid sync_id" do
      it "creates a new test sync and returns success" do
        request.headers.merge!(auth_headers(user, workspace_id))
        post :test, params: { id: sync.id }
        expect(Temporal).to have_received(:start_workflow).with(
          Workflows::SyncWorkflow,
          sync.id,
          "test",
          { options: { workflow_id: /^test-[a-f0-9]{16}-redshift-klaviyo-syncid-#{sync.id}$/ } }
        )
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "message" => "Sync test triggered successful" })

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("test")
        expect(audit_log.resource_type).to eq("Sync")
        expect(audit_log.resource_id).to eq(sync.id)
        expect(audit_log.resource).to eq(nil)
        expect(audit_log.workspace_id).to eq(workspace.id)
      end
    end

    context "when sync is disabled" do
      it "returns failure" do
        sync.update(status: "disabled")
        error_message = "Sync is disabled"
        request.headers.merge!(auth_headers(user, workspace_id))

        post :test, params: { id: sync.id }
        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(424)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end

    context "when sync id is incorrect" do
      it "returns failure" do
        error_message = "Sync not found"
        request.headers.merge!(auth_headers(user, workspace_id))

        post :test, params: { id: 514_254 }
        expect(response).to have_http_status(:not_found)
        result = JSON.parse(response.body)
        expect(result["errors"][0]["status"]).to eq(404)
        expect(result["errors"][0]["detail"]).to eq(error_message)
      end
    end
  end
end
