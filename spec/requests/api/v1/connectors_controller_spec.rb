# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ConnectorsController", type: :request do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:connectors) do
    [
      create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo"),
      create(:connector, workspace:, connector_type: "source", name: "redshift", connector_name: "Redshift")
    ]
  end

  describe "GET /api/v1/connectors" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/connectors"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and all connectors " do
        get "/api/v1/connectors", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(connectors.count)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
      end

      it "returns success and all source connectors" do
        get "/api/v1/connectors?type=source", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("source")
      end

      it "returns success and destination connectors" do
        get "/api/v1/connectors?type=destination", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(1)
        expect(response_hash.dig(:data, 0, :type)).to eq("connectors")
        expect(response_hash.dig(:data, 0, :attributes, :connector_type)).to eql("destination")
      end

      it "returns an error response for connectors" do
        get "/api/v1/connectors?type=destination1", headers: auth_headers(user)
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
        get "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user)
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
        get "/api/v1/connectors/test", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail)).to eq("Connector not found")
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
          .merge(auth_headers(user))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :workspace_id)).to eq(workspace.id)
        expect(response_hash.dig(:data, :attributes, :connector_type)).to eq("source")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")
        expect(response_hash.dig(:data, :attributes, :connector_name)).to eq("Redshift")
      end

      it "returns an error response when creation fails" do
        request_body[:connector][:connector_type] = "connector_type_wrong"
        post "/api/v1/connectors", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user))
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
          { "Content-Type": "application/json" }.merge(auth_headers(user))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(connectors.second.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("connectors")
        expect(response_hash.dig(:data, :attributes, :name)).to eq("AWS Redshift")
      end

      it "returns an error response when update fails" do
        request_body[:connector][:connector_type] = "connector_type_wrong"
        put "/api/v1/connectors/#{connectors.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user))
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
        get "/api/v1/connectors/#{connectors.first.id}/discover", headers: auth_headers(user)
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
        get "/api/v1/connectors/test/discover", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail)).to eq("Connector not found")
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
        delete "/api/v1/connectors/#{connectors.first.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:no_content)
      end

      it "returns an error response while delete wrong connector" do
        delete "/api/v1/connectors/test", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/connectors/id/query_source" do
    let(:connector) { create(:connector, connector_type: "source") }
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

    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        post "/api/v1/connectors/#{connectors.second.id}/query_source"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success status for a valid query" do
        allow(Connectors::QuerySource).to receive(:call)
          .and_return(double(:context, success?: true, records: [record1, record2]))
        post "/api/v1/connectors/#{connectors.second.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)
        expect(response_hash).to eq([record1.record.data, record2.record.data])
      end

      it "returns failure status for a invalid query" do
        allow(Connectors::QuerySource).to receive(:call).and_raise(StandardError, "query failed")

        post "/api/v1/connectors/#{connectors.second.id}/query_source", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user))

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
