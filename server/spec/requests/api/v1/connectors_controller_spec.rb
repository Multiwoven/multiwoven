# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ConnectorsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }
  let!(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
    ]
  end
  let!(:data_connector) { create(:connector, workspace:, connector_category: "Data Warehouse") }
  let!(:ai_ml_connector) { create(:connector, workspace:, connector_category: "AI Model") }
  let!(:other_connector) { create(:connector, workspace:, connector_category: "CRM") }

  before do
    user.confirm
  end

  describe "GET /api/v1/connectors" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connectors"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and all connectors admin role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/connectors", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count + 3)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns success and all connectors member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/connectors", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count + 3)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns success and all connectors viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/connectors", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count + 3)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns success and all connectors member role " do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/connectors", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count + 3)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns success and all source connectors" do
        get "/api/v1/connectors?type=source", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("source")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns success and destination connectors" do
        get "/api/v1/connectors?type=destination", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("destination")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/connectors?page=1")
      end

      it "returns only data connectors" do
        get "/api/v1/connectors?category=data", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result["data"].map { |connector| connector["id"] }).not_to include(ai_ml_connector.id.to_s)
      end

      it "returns only ai_ml connectors" do
        get "/api/v1/connectors?category=ai_ml", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result["data"].map { |connector| connector["id"] }).to eql([ai_ml_connector.id.to_s])
      end

      it "returns only ai_ml connectors for source" do
        get "/api/v1/connectors?type=source&&category=ai_ml", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        result = JSON.parse(response.body)
        expect(result["data"].count).to eql(0)
      end

      it "returns an error response for connectors" do
        get "/api/v1/connectors?type=destination1", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /api/v1/connectors/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connectors/#{connectors.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch connector " do
        get "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq(connectors.first.connector_type)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(connectors.first.name)
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq(connectors.first.connector_name)
      end

      it "returns success and fetch connector viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq(connectors.first.connector_type)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(connectors.first.name)
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq(connectors.first.connector_name)
      end

      it "returns success and fetch connector member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq(connectors.first.connector_type)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(connectors.first.name)
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq(connectors.first.connector_name)
      end

      it "returns an error response while fetch connector" do
        get "/api/v1/connectors/test", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, :id)).to eq(["must be an integer"])
      end
    end
  end

  describe "POST /api/v1/connectors - Create Connector" do
    request_body = {
      connector: {
        connector_type: "source",
        configuration: {
          credentials: {
            auth_type: "username/password",
            username: "test",
            password: "test"
          },
          host: "redshift-serverless.amazonaws.com",
          port: "5439",
          database: "dev",
          schema: "public"
        },
        name: "AWS Redshift",
        connector_name: "Redshift"
      }
    }

    context "when it is an unauthenticated user for create connector" do
      it "returns unauthorized" do
        post "/api/v1/connectors"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and create connector" do
      it "creates a new connector and returns success" do
        post "/api/v1/connectors", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq("source")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq("Redshift")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
        expect(audit_log.resource).to eq(request_body.dig(:connector, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{response_hash['data']['id'].to_i}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "creates a new connector and returns success for member role" do
        workspace.workspace_users.first.update(role: member_role)
        post "/api/v1/connectors", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq("source")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq("Redshift")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
        expect(audit_log.resource).to eq(request_body.dig(:connector, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{response_hash['data']['id'].to_i}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns unauthorize viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        post "/api/v1/connectors", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response when creation fails" do
        request_body[:connector][:connector_type] = "connector_type_wrong"
        post "/api/v1/connectors", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PUT /api/v1/connectors - Update Connector" do
    request_body = {
      connector: {
        connector_type: "source",
        configuration: {
          credentials: {
            auth_type: "username/password",
            username: "test",
            password: "test"
          },
          host: "redshift-serverless.amazonaws.com",
          port: "5439",
          database: "dev",
          schema: "public"
        },
        name: "AWS Redshift",
        connector_name: "Redshift"
      }
    }

    context "when it is an unauthenticated user for update connector" do
      it "returns unauthorized" do
        put "/api/v1/connectors/#{connectors.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and update connector" do
      it "updates the connector and returns success" do
        put "/api/v1/connectors/#{connectors.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.second.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connectors.second.id)
        expect(audit_log.resource).to eq(request_body.dig(:connector, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{connectors.second.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "updates the connector and returns success for member role" do
        workspace.workspace_users.first.update(role: member_role)
        put "/api/v1/connectors/#{connectors.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.second.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connectors.second.id)
        expect(audit_log.resource).to eq(request_body.dig(:connector, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{connectors.second.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns unauthorize viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        put "/api/v1/connectors/#{connectors.second.id}", params: request_body.to_json, headers:
        { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response when update fails" do
        request_body[:connector][:connector_type] = "connector_type_wrong"
        put "/api/v1/connectors/#{connectors.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /api/v1/connectors/id/discover" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connectors/#{connectors.first.id}/discover"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and discover object " do
        get "/api/v1/connectors/#{connectors.first.id}/discover", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connectors.first.id)
        expect(response_hash.dig(:data, :attributes, :catalog)).to be_present
        expect(response_hash.dig(:data, :attributes, :catalog, :streams)).to be_present
      end

      it "returns success and discover object for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/connectors/#{connectors.first.id}/discover", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connectors.first.id)
        expect(response_hash.dig(:data, :attributes, :catalog)).to be_present
        expect(response_hash.dig(:data, :attributes, :catalog, :streams)).to be_present
      end

      it "returns success and should not refresh the catalog when refresh flag is absent" do
        workspace.workspace_users.first.update(role: member_role)
        connector = connectors.first
        catalog = create(:catalog, connector:)
        get "/api/v1/connectors/#{connector.id}/discover", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :catalog)).to eq(catalog.catalog)
      end

      it "returns success and refresh the catalog when refresh is true" do
        workspace.workspace_users.first.update(role: member_role)
        connector = connectors.first
        catalog = create(:catalog, connector:)
        get "/api/v1/connectors/#{connector.id}/discover?refresh=true", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :catalog)).not_to eq(catalog.catalog)
      end

      it "returns success and discover object for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/connectors/#{connectors.first.id}/discover", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("catalogs")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_id)).to eq(connectors.first.id)
        expect(response_hash.dig(:data, :attributes, :catalog)).to be_present
        expect(response_hash.dig(:data, :attributes, :catalog, :streams)).to be_present
      end

      it "returns an error response while get discover object" do
        get "/api/v1/connectors/test/discover", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, :id)).to eq(["must be an integer"])
      end
    end
  end

  describe "DELETE /api/v1/connectors/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete "/api/v1/connectors/#{connectors.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and delete connector" do
        delete "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connectors.first.id)
        expect(audit_log.resource).to eq(connectors.first.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns success and delete connector" do
        workspace.workspace_users.first.update(role: member_role)
        delete "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connectors.first.id)
        expect(audit_log.resource).to eq(connectors.first.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns fail viwer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        delete "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response while delete wrong connector" do
        delete "/api/v1/connectors/test", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "POST /api/v1/connectors/id/query_source" do
    let(:connector) { create(:connector, connector_type: "source", workspace:, connector_name: "AmazonS3") }
    let(:query) { "SELECT * FROM table_name" }
    let(:limit) { 50 }
    let(:record1) do
      Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1 },
                                                            emitted_at: DateTime.now.to_i).to_multiwoven_message
    end
    let(:record2) do
      Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 2 },
                                                            emitted_at: DateTime.now.to_i).to_multiwoven_message
    end

    let(:request_body) do
      {
        query: "SELECT * FROM table_name"
      }
    end

    before do
      create(:catalog, connector_id: connector.id, workspace:)
    end

    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        post "/api/v1/connectors/#{connector.id}/query_source"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success status for a valid query" do
        allow(Connectors::QuerySource).to receive(:call)
          .and_return(double(:context, success?: true, records: [record1, record2]))
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data]).to eq([record1.record.data, record2.record.data])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("query_source")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connector.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns success status for a valid query for member role" do
        workspace.workspace_users.first.update(role: member_role)
        allow(Connectors::QuerySource).to receive(:call)
          .and_return(double(:context, success?: true, records: [record1, record2]))
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data]).to eq([record1.record.data, record2.record.data])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("query_source")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connector.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns an error message for missing catalog for ai connectors" do
        catalog = connector.catalog
        catalog.connector_id = connectors.second.id
        catalog.save
        # rubocop:disable Rails/SkipsModelValidations
        connector.update_column(:connector_category, "AI Model")
        # rubocop:enable Rails/SkipsModelValidations

        allow(Connectors::QuerySource).to receive(:call).and_return(double(:context, success?: true,
                                                                                     records: [record1, record2]))
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace.id))
        expect(response).to have_http_status(:unprocessable_entity)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail)).to eq("Catalog is not present for the connector")
      end

      it "should not return error message for missing catalog for data connectors" do
        catalog = connector.catalog
        catalog.connector_id = connectors.second.id
        # rubocop:disable Rails/SkipsModelValidations
        connector.update_column(:connector_category, "Data Warehouse")
        # rubocop:enable Rails/SkipsModelValidations
        catalog.save

        allow(Connectors::QuerySource).to receive(:call).and_return(double(:context, success?: true,
                                                                                     records: [record1, record2]))
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace.id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data]).to eq([record1.record.data, record2.record.data])
      end

      it "returns success status for a valid query for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        allow(Connectors::QuerySource).to receive(:call)
          .and_return(double(:context, success?: true, records: [record1, record2]))
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data]).to eq([record1.record.data, record2.record.data])

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("query_source")
        expect(audit_log.resource_type).to eq("Connector")
        expect(audit_log.resource_id).to eq(connector.id)
        expect(audit_log.resource).to eq(connector.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/setup/sources/Data%20Sources/#{connector.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns failure status for a invalid query" do
        allow(Connectors::QuerySource).to receive(:call).and_raise(StandardError, "query failed")

        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))

        expect(response).to have_http_status(:bad_request)
      end

      it "returns failure status for a invalid query" do
        request_body[:query] = "invalid"
        post "/api/v1/connectors/#{connector.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#validate_query" do
    let(:request_body) do
      {
        query: "SELECT * FROM table_name"
      }
    end
    before do
      allow(Utils::QueryValidator).to receive(:validate_query).and_return(nil)
    end

    context "when query is valid" do
      it "does not raise an error" do
        expect do
          post "/api/v1/connectors/#{connectors.second.id}/query_source", params: request_body.to_json, headers:
            { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        end.not_to raise_error
      end
    end

    # context "when query is invalid" do
    #   before do
    #     allow(Utils::QueryValidator).to receive(:validate_query).and_raise(StandardError, "Invalid query")
    #   end

    #   it "renders an error message" do
    #     post "/api/v1/connectors/#{connectors.second.id}/query_source", params: request_body.to_json, headers:
    #         { "Content-Type": "application/json" }.merge(auth_headers(user))
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.body).to include("Query validation failed: Invalid query")
    #   end
    # end
  end
end
