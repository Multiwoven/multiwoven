# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::CatalogsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }
  let(:admin_role) { create(:role, :admin) }
  let(:connector) do
    create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo")
  end

  let(:existing_catalog) do
    create(:catalog, connector:, catalog: { "streams" => [{ "name" => "Old Catalog", "json_schema" => {} }] })
  end

  let(:request_body) do
    {
      connector_id: connector.id,
      catalog: {
        "json_schema" => {
          "input" => [
            {
              "name" => "val1",
              "type" => "string"
            }
          ],
          "output" => [
            {
              "name" => "val1",
              "type" => "string"
            }
          ]
        }
      }
    }
  end

  let(:update_request_body) do
    {
      connector_id: connector.id,
      catalog: {
        "json_schema" => {
          "input" => [
            {
              "updated_name" => "val1",
              "updated_type" => "string"
            }
          ],
          "output" => [
            {
              "name" => "val1",
              "type" => "string"
            }
          ]
        }
      }
    }
  end

  before do
    user.confirm
  end
  describe "POST #create" do
    context "when it is an unauthenticated user for create catalog" do
      it "returns unauthorized" do
        post "/api/v1/catalogs"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "user is admin" do
      it "creates catalog" do
        workspace.workspace_users.first.update(role: admin_role)

        post "/api/v1/catalogs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connector.id)
        expect(response_hash.dig(:data, :attributes, :catalog, :streams).first["name"]).to eq(connector.name)
        expect(response_hash.dig(:data, :attributes, :catalog,
                                 :streams).first["json_schema"]).to eq(request_body[:catalog]["json_schema"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Catalog")
        expect(audit_log.resource_id).to eq(connector.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/destinations/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "user is member" do
      it "shouldn't create catalog" do
        workspace.workspace_users.first.update(role: member_role)

        post "/api/v1/catalogs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connector.id)
        expect(response_hash.dig(:data, :attributes, :catalog, :streams).first["name"]).to eq(connector.name)
        expect(response_hash.dig(:data, :attributes, :catalog,
                                 :streams).first["json_schema"]).to eq(request_body[:catalog]["json_schema"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Catalog")
        expect(audit_log.resource_id).to eq(connector.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/destinations/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "user is viewer" do
      it "shouldn't create catalog" do
        workspace.workspace_users.first.update(role: viewer_role)

        post "/api/v1/catalogs", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT #update" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        put "/api/v1/catalogs/#{existing_catalog.id}",
            params: update_request_body.to_json,
            headers: { "Content-Type": "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "user is admin" do
      it "updates the catalog" do
        workspace.workspace_users.first.update(role: admin_role)

        put "/api/v1/catalogs/#{existing_catalog.id}",
            params: update_request_body.to_json,
            headers: { "Content-Type": "application/json" }
              .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connector.id)
        expect(response_hash.dig(:data, :attributes, :catalog,
                                 :streams).first["json_schema"]).to eq(update_request_body[:catalog]["json_schema"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Catalog")
        expect(audit_log.resource_id).to eq(existing_catalog.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/destinations/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "user is member" do
      it "updates the catalog" do
        workspace.workspace_users.first.update(role: member_role)

        put "/api/v1/catalogs/#{existing_catalog.id}",
            params: update_request_body.to_json,
            headers: { "Content-Type": "application/json" }
              .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connector.id)
        expect(response_hash.dig(:data, :attributes, :catalog,
                                 :streams).first["json_schema"]).to eq(update_request_body[:catalog]["json_schema"])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Catalog")
        expect(audit_log.resource_id).to eq(existing_catalog.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/destinations/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "user is viewer" do
      it "updates the catalog" do
        workspace.workspace_users.first.update(role: viewer_role)

        put "/api/v1/catalogs/#{existing_catalog.id}",
            params: update_request_body.to_json,
            headers: { "Content-Type": "application/json" }
              .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
