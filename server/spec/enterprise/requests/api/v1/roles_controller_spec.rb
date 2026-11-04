# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::RolesController, type: :controller do
  # rubocop:disable Layout/LineLength
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let!(:viewer_role) { create(:role, role_name: "Viewer") }
  let!(:member_role) { create(:role, role_name: "Member") }

  before(:all) do
    Role.destroy_all
  end

  before do
    user.update!(confirmed_at: Time.current)
  end

  describe "GET /enterprise/api/v1/roles" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch all roles" do
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        # expect(response_hash[:data].size).to eq(3)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :role_name)).to eql(workspace.workspace_users.first.role.role_name)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :role_desc)).to eql(workspace.workspace_users.first.role.role_desc)

        grouped_policies = JSON.parse(workspace.workspace_users.first.role.grouped_policies.to_json)
        expect(response_hash.dig(:data, 0, :attributes,
                                 :policies)).to eql(grouped_policies)
      end

      it "returns success and fetch all roles for member role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
        get :index
        expect(response).to have_http_status(:ok)
      end

      it "returns success and fetch all roles for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /enterprise/api/v1/roles" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        post :create, params: {
          role: {
            role_name: "Admin",
            policies: {}
          }
        }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when creating a new role" do
      it "creates a new role successfully" do
        request.headers.merge!(auth_headers(user, workspace_id))
        post :create, params: {
          role: {
            role_name: "Test Admin",
            role_desc: "Administrative role with all permissions",
            policies: {
              permissions: {
                connector_definition: { create: true, read: true, update: true, delete: true },
                connector: { create: true, read: true, update: true, delete: true },
                model: { create: true, read: true, update: true, delete: true },
                report: { create: true, read: true, update: true, delete: true },
                sync_record: { create: true, read: true, update: true, delete: true },
                sync_run: { create: true, read: true, update: true, delete: true },
                sync: { create: true, read: true, update: true, delete: true },
                user: { create: true, read: true, update: true, delete: true },
                workspace: { create: true, read: true, update: true, delete: true },
                data_app: { create: true, read: true, update: true, delete: true },
                audit_logs: { create: true, read: true, update: true, delete: true },
                alerts: { create: true, read: true, update: true, delete: true },
                billing: { create: true, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:created)
        role = Role.find(JSON.parse(response.body)["data"]["id"])
        expect(JSON.parse(role.grouped_policies.to_json)).to eq(JSON.parse(response.body)["data"]["attributes"]["policies"])
        expect(role.role_desc).to eq("Administrative role with all permissions")
        expect(JSON.parse(role.group_permissions_count.to_json)).to eq(JSON.parse(response.body)["data"]["attributes"]["group_permissions_count"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Role")
        expect(audit_log.resource_id).to eq(role.id)
        expect(audit_log.resource).to eq(role.role_name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/organization/roles")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "unauthorized for members to create role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
        post :create, params: {
          role: {
            role_name: "Admin",
            policies: {
              permissions: {
                connector_definition: { create: true, read: true, update: true, delete: true },
                connector: { create: true, read: true, update: true, delete: true },
                model: { create: true, read: true, update: true, delete: true },
                report: { create: true, read: true, update: true, delete: true },
                sync_record: { create: true, read: true, update: true, delete: true },
                sync_run: { create: true, read: true, update: true, delete: true },
                sync: { create: true, read: true, update: true, delete: true },
                user: { create: true, read: true, update: true, delete: true },
                workspace: { create: true, read: true, update: true, delete: true },
                data_app: { create: true, read: true, update: true, delete: true },
                audit_logs: { create: true, read: true, update: true, delete: true },
                alerts: { create: true, read: true, update: true, delete: true },
                billing: { create: true, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:forbidden)
      end

      it "unauthorized for viewers to create role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: viewer_role)
        post :create, params: {
          role: {
            role_name: "Admin",
            policies: {
              permissions: {
                connector_definition: { create: true, read: true, update: true, delete: true },
                connector: { create: true, read: true, update: true, delete: true },
                model: { create: true, read: true, update: true, delete: true },
                report: { create: true, read: true, update: true, delete: true },
                sync_record: { create: true, read: true, update: true, delete: true },
                sync_run: { create: true, read: true, update: true, delete: true },
                sync: { create: true, read: true, update: true, delete: true },
                user: { create: true, read: true, update: true, delete: true },
                workspace: { create: true, read: true, update: true, delete: true },
                data_app: { create: true, read: true, update: true, delete: true },
                audit_logs: { create: true, read: true, update: true, delete: true },
                alerts: { create: true, read: true, update: true, delete: true },
                billing: { create: true, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PUT /enterprise/api/v1/roles/:id" do
    let!(:role) { create(:role, :custom, organization: workspace.organization) }

    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        put :update, params: { id: role.id, role: { role_name: "Updated Custom Role", policies: {} } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when updating an existing role" do
      it "updates the role successfully" do
        request.headers.merge!(auth_headers(user, workspace_id))
        put :update, params: {
          id: role.id,
          role: {
            role_name: "Updated Custom Role",
            role_desc: "Updated description for the custom role",
            policies: {
              permissions: {
                connector_definition: { create: false, read: true, update: true, delete: true },
                connector: { create: false, read: true, update: true, delete: true },
                model: { create: false, read: true, update: true, delete: true },
                report: { create: false, read: true, update: true, delete: true },
                sync_record: { create: false, read: true, update: true, delete: true },
                sync_run: { create: false, read: true, update: true, delete: true },
                sync: { create: false, read: true, update: true, delete: true },
                user: { create: false, read: true, update: true, delete: true },
                workspace: { create: false, read: true, update: true, delete: true },
                data_app: { create: false, read: true, update: true, delete: true },
                audit_logs: { create: false, read: true, update: true, delete: true },
                alerts: { create: false, read: true, update: true, delete: true },
                billing: { create: false, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:ok)
        expect(role.reload.role_name).to eq("Updated Custom Role")
        expect(role.reload.role_desc).to eq("Updated description for the custom role")
        expect(JSON.parse(role.grouped_policies.to_json)).to eq(JSON.parse(response.body)["data"]["attributes"]["policies"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Role")
        expect(audit_log.resource_id).to eq(role.id)
        expect(audit_log.resource).to eq(role.role_name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/organization/roles")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "member cannot update role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
        put :update, params: {
          id: role.id,
          role: {
            role_name: "Updated Custom Role",
            policies: {
              permissions: {
                connector_definition: { create: false, read: true, update: true, delete: true },
                connector: { create: false, read: true, update: true, delete: true },
                model: { create: false, read: true, update: true, delete: true },
                report: { create: false, read: true, update: true, delete: true },
                sync_record: { create: false, read: true, update: true, delete: true },
                sync_run: { create: false, read: true, update: true, delete: true },
                sync: { create: false, read: true, update: true, delete: true },
                user: { create: false, read: true, update: true, delete: true },
                workspace: { create: false, read: true, update: true, delete: true },
                data_app: { create: false, read: true, update: true, delete: true },
                audit_logs: { create: false, read: true, update: true, delete: true },
                alerts: { create: false, read: true, update: true, delete: true },
                billing: { create: false, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:forbidden)
      end

      it "viewer cannot update role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: viewer_role)
        put :update, params: {
          id: role.id,
          role: {
            role_name: "Updated Custom Role",
            policies: {
              permissions: {
                connector_definition: { create: false, read: true, update: true, delete: true },
                connector: { create: false, read: true, update: true, delete: true },
                model: { create: false, read: true, update: true, delete: true },
                report: { create: false, read: true, update: true, delete: true },
                sync_record: { create: false, read: true, update: true, delete: true },
                sync_run: { create: false, read: true, update: true, delete: true },
                sync: { create: false, read: true, update: true, delete: true },
                user: { create: false, read: true, update: true, delete: true },
                workspace: { create: false, read: true, update: true, delete: true },
                data_app: { create: false, read: true, update: true, delete: true },
                audit_logs: { create: false, read: true, update: true, delete: true },
                alerts: { create: false, read: true, update: true, delete: true },
                billing: { create: false, read: true, update: true, delete: true },
                hosted_datastore: { create: true, read: true, update: true, delete: true },
                knowledge_base: { create: true, read: true, update: true, delete: true },
                spending_limit: { create: true, read: true, update: true, delete: true }
              }
            }
          }
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /enterprise/api/v1/roles/:id" do
    let!(:role) { create(:role, :custom, organization: workspace.organization) }

    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when deleting an existing role" do
      it "deletes the role successfully" do
        request.headers.merge!(auth_headers(user, workspace_id))
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:no_content)
        expect(Role.exists?(role.id)).to be_falsey

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Role")
        expect(audit_log.resource_id).to eq(role.id)
        expect(audit_log.resource).to eq(role.role_name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to be_nil
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "deletes the role successfully" do
        request.headers.merge!(auth_headers(user, workspace_id))
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:no_content)
        expect(Role.exists?(role.id)).to be_falsey

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Role")
        expect(audit_log.resource_id).to eq(role.id)
        expect(audit_log.resource).to eq(role.role_name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to be_nil
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "viewer cannot delete the role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: viewer_role)
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "member cannot delete the role" do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /enterprise/api/v1/roles/resources" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :resources
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when fetching resources" do
      it "returns the available resources successfully" do
        request.headers.merge!(auth_headers(user, workspace_id))
        get :resources
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["resources"]).to eq(JSON.parse(Utils::Constants::RESOURCE_GROUP_MAPPING.to_json))
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
