# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ConnectorDefinitions", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:service) { Multiwoven::Integrations::Service }
  let(:connection_status) { Multiwoven::Integrations::Protocol::ConnectionStatus }
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  describe "GET /api/v1/connector_definitions" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connector_definitions"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success" do
        get "/api/v1/connector_definitions", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:source].count).to eql(service.connectors[:source].count)
        expect(response_hash[:destination].count).to eql(service.connectors[:destination].count)
      end

      it "returns success viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/connector_definitions", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:source].count).to eql(service.connectors[:source].count)
        expect(response_hash[:destination].count).to eql(service.connectors[:destination].count)
      end

      it "returns success member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/connector_definitions", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:source].count).to eql(service.connectors[:source].count)
        expect(response_hash[:destination].count).to eql(service.connectors[:destination].count)
      end
    end
  end

  describe "GET /api/v1/connector_definitions/:id" do
    it "returns a connector when found" do
      get api_v1_connector_definition_path(id: "Snowflake", type: "source"),
          headers: auth_headers(user, workspace_id)
      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body).with_indifferent_access

      expect(response_hash[:name]).to eql("Snowflake")
      expect(response_hash[:connector_type]).to eql("source")
    end

    it "returns a connector when found for member role" do
      workspace.workspace_users.first.update(role: member_role)
      get api_v1_connector_definition_path(id: "Snowflake", type: "source"),
          headers: auth_headers(user, workspace_id)
      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body).with_indifferent_access

      expect(response_hash[:name]).to eql("Snowflake")
      expect(response_hash[:connector_type]).to eql("source")
    end

    it "returns a connector when found for viewer role" do
      workspace.workspace_users.first.update(role: member_role)
      get api_v1_connector_definition_path(id: "Snowflake", type: "source"),
          headers: auth_headers(user, workspace_id)
      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body).with_indifferent_access

      expect(response_hash[:name]).to eql("Snowflake")
      expect(response_hash[:connector_type]).to eql("source")
    end

    it "returns empty array not found" do
      get api_v1_connector_definition_path(id: "Unknown", type: "source"),
          headers: auth_headers(user, workspace_id)
      expect(response).to have_http_status(:ok)
      response_hash = JSON.parse(response.body)

      expect(response_hash).to eql({ "data" => [] })
    end
  end

  describe "POST /api/v1/connector_definitions/check_connection" do
    let(:mock_connector_class) { class_double("Multiwoven::Integrations::Source::Snowflake::Client") }
    let(:mock_connector_instance) { instance_double("Multiwoven::Integrations::Source::Snowflake::Client") }

    before do
      allow(Multiwoven::Integrations::Service).to receive(:connector_class)
        .with("Source", "Snowflake")
        .and_return(mock_connector_class)
      allow(mock_connector_class).to receive(:new).and_return(mock_connector_instance)
    end

    it "returns success status for a valid connection" do
      allow(mock_connector_instance).to receive(:check_connection)
        .and_return(connection_status.new(status: "succeeded").to_multiwoven_message)

      post check_connection_api_v1_connector_definitions_path,
           params: { type: "source", name: "Snowflake", connection_spec: { test: "test" } },
           headers: auth_headers(user, workspace_id)

      expect(response).to have_http_status(:ok)

      response_hash = JSON.parse(response.body).with_indifferent_access
      expect(response_hash[:connection_status][:status]).to eql("succeeded")
    end

    it "returns success status for a valid connection fro member role" do
      workspace.workspace_users.first.update(role: member_role)
      allow(mock_connector_instance).to receive(:check_connection)
        .and_return(connection_status.new(status: "succeeded").to_multiwoven_message)

      post check_connection_api_v1_connector_definitions_path,
           params: { type: "source", name: "Snowflake", connection_spec: { test: "test" } },
           headers: auth_headers(user, workspace_id)

      expect(response).to have_http_status(:ok)

      response_hash = JSON.parse(response.body).with_indifferent_access
      expect(response_hash[:connection_status][:status]).to eql("succeeded")
    end

    it "returns authorization failure for a view role user" do
      workspace.workspace_users.first.update(role: viewer_role)
      allow(mock_connector_instance).to receive(:check_connection)
        .and_return(connection_status.new(status: "succeeded").to_multiwoven_message)

      post check_connection_api_v1_connector_definitions_path,
           params: { type: "source", name: "Snowflake", connection_spec: { test: "test" } },
           headers: auth_headers(user, workspace_id)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns failure status for a valid connection" do
      allow(mock_connector_instance).to receive(:check_connection)
        .and_return(connection_status.new(status: "failed").to_multiwoven_message)

      post check_connection_api_v1_connector_definitions_path,
           params: { type: "source", name: "Snowflake", connection_spec: { test: "test" } },
           headers: auth_headers(user, workspace_id)

      expect(response).to have_http_status(:ok)

      response_hash = JSON.parse(response.body).with_indifferent_access
      expect(response_hash[:connection_status][:status]).to eql("failed")
    end
  end
end
