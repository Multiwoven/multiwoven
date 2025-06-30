# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::WorkspacesController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  let(:png_file) do
    Tempfile.new(["test_file", ".png"]).tap do |f|
      f.write("test")
      f.rewind
    end
  end
  let(:uploaded_file) do
    ActionDispatch::Http::UploadedFile.new(
      tempfile: png_file,
      filename: "test_file.png",
      content_type: "image/png"
    )
  end

  before do
    user.confirm
  end

  describe "GET /api/v1/workspaces" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/workspaces"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and get workspaces " do
        get "/api/v1/workspaces", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("workspaces")
      end

      it "returns success and get workspaces for workspace header 0" do
        get "/api/v1/workspaces", headers: auth_headers(user, 0)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("workspaces")
      end

      it "returns success and get workspaces for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/workspaces", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("workspaces")
      end

      it "returns success and get workspaces for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/workspaces", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("workspaces")
      end
    end
  end

  describe "GET /api/v1/workspaces/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/workspaces/#{workspace.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user fo" do
      it "returns success and get workspace by id for viewer_role" do
        workspace.file.attach(uploaded_file)
        workspace.organization.file.attach(uploaded_file)
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :type)).to eq("workspaces")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(workspace.name)
        expect(response_hash.dig(:data, :attributes, :slug)).to eq(workspace.slug)
        expect(response_hash.dig(:data, :attributes, :organization_id)).to eq(workspace.organization.id)
        expect(response_hash.dig(:data, :attributes, :organization_name)).to eq(workspace.organization.name)
        expect(response_hash.dig(:data, :attributes, :members_count))
          .to eq(workspace.users.count)
        expect(response_hash.dig(:data, :attributes, :workspace_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url))
          .not_to eq(response_hash.dig(:data, :attributes, :workspace_logo_url))
      end

      it "returns success and get workspace by id for workspace header 0" do
        workspace.file.attach(uploaded_file)
        workspace.organization.file.attach(uploaded_file)
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, 0)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :type)).to eq("workspaces")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(workspace.name)
        expect(response_hash.dig(:data, :attributes, :slug)).to eq(workspace.slug)
        expect(response_hash.dig(:data, :attributes, :organization_id)).to eq(workspace.organization.id)
        expect(response_hash.dig(:data, :attributes, :organization_name)).to eq(workspace.organization.name)
        expect(response_hash.dig(:data, :attributes, :members_count))
          .to eq(workspace.users.count)
        expect(response_hash.dig(:data, :attributes, :workspace_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url))
          .not_to eq(response_hash.dig(:data, :attributes, :workspace_logo_url))
      end

      it "returns success and get workspace by id for member role" do
        workspace.file.attach(uploaded_file)
        workspace.organization.file.attach(uploaded_file)
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :type)).to eq("workspaces")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(workspace.name)
        expect(response_hash.dig(:data, :attributes, :slug)).to eq(workspace.slug)
        expect(response_hash.dig(:data, :attributes, :organization_id)).to eq(workspace.organization.id)
        expect(response_hash.dig(:data, :attributes, :organization_name)).to eq(workspace.organization.name)
        expect(response_hash.dig(:data, :attributes, :members_count))
          .to eq(workspace.users.count)
        expect(response_hash.dig(:data, :attributes, :workspace_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url))
          .not_to eq(response_hash.dig(:data, :attributes, :workspace_logo_url))
      end

      it "returns success and get workspace by id " do
        workspace.file.attach(uploaded_file)
        workspace.organization.file.attach(uploaded_file)
        get "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :type)).to eq("workspaces")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(workspace.name)
        expect(response_hash.dig(:data, :attributes, :slug)).to eq(workspace.slug)
        expect(response_hash.dig(:data, :attributes, :organization_id)).to eq(workspace.organization.id)
        expect(response_hash.dig(:data, :attributes, :organization_name)).to eq(workspace.organization.name)
        expect(response_hash.dig(:data, :attributes, :members_count))
          .to eq(workspace.users.count)
        expect(response_hash.dig(:data, :attributes, :workspace_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :organization_logo_url))
          .not_to eq(response_hash.dig(:data, :attributes, :workspace_logo_url))
      end
    end
  end

  describe "POST /api/v1/workspaces - Create workspace" do
    let(:request_body) do
      {
        workspace: {
          name: "workspace_test",
          organization_id: workspace.organization.id,
          description: "",
          region: "us-west"
        }
      }
    end

    context "when it is an unauthenticated user for create workspace" do
      it "returns unauthorized" do
        post "/api/v1/workspaces"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and create workspace" do
      it "creates a new workspace and returns success" do
        post "/api/v1/workspaces", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("workspaces")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:workspace, :name))
        expect(response_hash.dig(:data, :attributes, :slug)).to eq("workspace_test")
        expect(response_hash.dig(:data, :attributes, :status)).to eq("pending")
        expect(response_hash.dig(:data, :attributes, :description)).to eq("")
        expect(response_hash.dig(:data, :attributes, :region)).to eq("us-west")
        expect(response_hash.dig(:data, :attributes, :organization_id))
          .to eq(request_body.dig(:workspace, :organization_id))
        expect(response_hash.dig(:data, :attributes, :members_count))
          .to eq(workspace.users.count)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Workspace")
        expect(audit_log.resource_id).to eq(response_hash.dig(:data, :id).to_i)
        expect(audit_log.resource).to eq(response_hash.dig(:data, :attributes, :name))
        expect(audit_log.workspace_id).to eq(workspace_id)
        expect(audit_log.resource_link).to eq("/reports/#{response_hash.dig(:data, :id)}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "creates a new workspace and returns success for member_role" do
        workspace.workspace_users.first.update(role: member_role)
        post "/api/v1/workspaces", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:forbidden)
      end

      it "creates a new workspace and returns success for viewer_role" do
        workspace.workspace_users.first.update(role: viewer_role)
        post "/api/v1/workspaces", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:forbidden)
      end

      it "returns an error response when creation fails" do
        request_body[:workspace][:organization_id] = "organization_id_wrong"
        post "/api/v1/workspaces", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PUT /api/v1/workspaces/id - Update workspace" do
    let(:request_body) do
      {
        workspace: {
          name: "workspace_test",
          organization_id: workspace.organization.id,
          description: "workspace description changes",
          region: "us-west2"
        }
      }
    end

    context "when it is an unauthenticated user for update workspace" do
      it "returns unauthorized" do
        put "/api/v1/workspaces/#{workspace.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and update workspace" do
      it "updates the workspace and returns success" do
        request_body[:workspace][:name] = "test"
        put "/api/v1/workspaces/#{workspace.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(workspace.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq("test")
        expect(response_hash.dig(:data, :attributes, :description)).to eq("workspace description changes")
        expect(response_hash.dig(:data, :attributes, :region)).to eq("us-west2")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Workspace")
        expect(audit_log.resource_id).to eq(response_hash.dig(:data, :id).to_i)
        expect(audit_log.resource).to eq(response_hash.dig(:data, :attributes, :name))
        expect(audit_log.workspace_id).to eq(workspace_id)
        expect(audit_log.resource_link).to eq("/reports/#{response_hash.dig(:data, :id)}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "updates the workspace and returns success if slug is missing" do
        workspace.slug = ""
        request_body[:workspace][:name] = "test"
        put "/api/v1/workspaces/#{workspace.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(workspace.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq("test")
        expect(response_hash.dig(:data, :attributes, :description)).to eq("workspace description changes")
        expect(response_hash.dig(:data, :attributes, :region)).to eq("us-west2")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Workspace")
        expect(audit_log.resource_id).to eq(response_hash.dig(:data, :id).to_i)
        expect(audit_log.resource).to eq(response_hash.dig(:data, :attributes, :name))
        expect(audit_log.workspace_id).to eq(workspace_id)
        expect(audit_log.resource_link).to eq("/reports/#{response_hash.dig(:data, :id)}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "updates the workspace and returns success for viewer_role" do
        request_body[:workspace][:name] = "test"
        workspace.workspace_users.first.update(role: viewer_role)
        put "/api/v1/workspaces/#{workspace.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:forbidden)
      end

      it "updates the workspace and returns success for member_role" do
        request_body[:workspace][:name] = "test"
        workspace.workspace_users.first.update(role: member_role)
        put "/api/v1/workspaces/#{workspace.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:forbidden)
      end

      it "returns an error response when wrong workspace_id" do
        put "/api/v1/workspaces/test", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error response when update fails" do
        request_body[:workspace][:organization_id] = "organization_id_wrong"
        put "/api/v1/workspaces/#{workspace.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE /api/v1/workspaces/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete "/api/v1/workspaces/#{workspace.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and delete workspace" do
        delete "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Workspace")
        expect(audit_log.resource_id).to eq(workspace_id)
        expect(audit_log.resource).to eq(workspace.name)
        expect(audit_log.workspace_id).to eq(nil)
        expect(audit_log.resource_link).to eq(nil)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns success and delete workspace for viewer_role" do
        workspace.workspace_users.first.update(role: viewer_role)
        delete "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:forbidden)
      end

      it "returns success and delete workspace for member_role" do
        workspace.workspace_users.first.update(role: member_role)
        delete "/api/v1/workspaces/#{workspace.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:forbidden)
      end

      it "returns an error response while delete wrong workspace" do
        delete "/api/v1/workspaces/test", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
