# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ModelsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:connector) do
    create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo")
  end
  let!(:models) do
    [
      create(:model, connector:, workspace:, name: "model1", query: "SELECT * FROM locations"),
      create(:model, connector:, workspace:, name: "model2", query: "SELECT * FROM locations")
    ]
  end
  let(:viewer_role) { create(:role, role_name: "Viewer") }
  let(:member_role) { create(:role, role_name: "Member") }

  describe "GET /api/v1/models" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/models"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and all model " do
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(models.count)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
      end

      it "returns success and all mode for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(models.count)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
      end

      it "returns success and all model for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(models.count)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
      end
    end
  end

  describe "GET /api/v1/models/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/models/#{models.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and fetch model " do
        get "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(models.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("models")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(models.first.name)
        expect(response_hash.dig(:data, :attributes, :query)).to eq(models.first.query)
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(models.first.query_type)
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(models.first.primary_key)
      end

      it "returns success and fetch model for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(models.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("models")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(models.first.name)
        expect(response_hash.dig(:data, :attributes, :query)).to eq(models.first.query)
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(models.first.query_type)
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(models.first.primary_key)
      end

      it "returns success and fetch model for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(models.first.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("models")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(models.first.name)
        expect(response_hash.dig(:data, :attributes, :query)).to eq(models.first.query)
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(models.first.query_type)
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(models.first.primary_key)
      end

      it "returns an error response while fetch model" do
        get "/api/v1/models/test", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "POST /api/v1/models - Create model" do
    let(:request_body) do
      {
        model: {
          connector_id: models.first.connector_id,
          name: "Redshift Location",
          query: "SELECT * FROM locations",
          query_type: "raw_sql",
          primary_key: "id"
        }
      }
    end

    context "when it is an unauthenticated user for create model" do
      it "returns unauthorized" do
        post "/api/v1/models"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and create model" do
      it "creates a new model and returns success" do
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
        expect(response_hash.dig(:data, :attributes, :query)).to eq(request_body.dig(:model, :query))
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(request_body.dig(:model, :query_type))
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(request_body.dig(:model, :primary_key))
      end

      it "creates a new model and returns success" do
        workspace.workspace_users.first.update(role: member_role)
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
        expect(response_hash.dig(:data, :attributes, :query)).to eq(request_body.dig(:model, :query))
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(request_body.dig(:model, :query_type))
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(request_body.dig(:model, :primary_key))
      end

      it "creates a new model with query type table selector" do
        request = request_body
        request[:model][:query_type] = "table_selector"
        post "/api/v1/models", params: request.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))

        expect(response).to have_http_status(:created)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
        expect(response_hash.dig(:data, :attributes, :query)).to eq(request_body.dig(:model, :query))
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq("table_selector")
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(request_body.dig(:model, :primary_key))
      end

      it "returns fail viwer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response when creation fails" do
        request_body[:model][:connector_id] = "connector_id_wrong"
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PUT /api/v1/models - Update model" do
    let(:request_body) do
      {
        model: {
          connector_id: models.first.connector_id,
          name: "Redshift Location",
          query: "SELECT * FROM locations",
          query_type: "raw_sql",
          primary_key: "id"
        }
      }
    end

    context "when it is an unauthenticated user for update model" do
      it "returns unauthorized" do
        put "/api/v1/models/#{models.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user and update model" do
      it "updates the model and returns success" do
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(models.second.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
        expect(response_hash.dig(:data, :attributes, :query)).to eq(request_body.dig(:model, :query))
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(request_body.dig(:model, :query_type))
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(request_body.dig(:model, :primary_key))
      end

      it "updates the model and returns success for member role" do
        workspace.workspace_users.first.update(role: member_role)
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(models.second.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
        expect(response_hash.dig(:data, :attributes, :query)).to eq(request_body.dig(:model, :query))
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(request_body.dig(:model, :query_type))
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(request_body.dig(:model, :primary_key))
      end

      it "returns fail for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response when wrong model_id" do
        put "/api/v1/models/test", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error response when update fails" do
        request_body[:model][:connector_id] = "connector_id_wrong"
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
          { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE /api/v1/models/id" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete "/api/v1/models/#{models.first.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and delete model " do
        delete "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)
      end

      it "returns success and delete model for member role" do
        workspace.workspace_users.first.update(role: member_role)
        delete "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)
      end

      it "returns for viwer role " do
        workspace.workspace_users.first.update(role: viewer_role)
        delete "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns an error response while delete wrong model" do
        delete "/api/v1/models/99", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#validate_query" do
    before do
      allow(Utils::QueryValidator).to receive(:validate_query).and_return(nil)
    end
    let(:request_body) do
      {
        model: {
          connector_id: models.first.connector_id,
          name: "Redshift Location",
          query: "SELECT * FROM locations",
          query_type: "raw_sql",
          primary_key: "id"
        }
      }
    end

    context "when query is valid for create model" do
      it "does not raise an error" do
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
      end
    end

    # TODO: Enable this once we have query validation implemented for all the connectors
    # context "when query is invalid for create model" do
    #   before do
    #     allow(Utils::QueryValidator).to receive(:validate_query).and_raise(StandardError, "Invalid query")
    #   end

    #   it "renders an error message" do
    #     post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
    #       .merge(auth_headers(user))
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.body).to include("Query validation failed: Invalid query")
    #   end
    # end

    context "when query is valid for update model" do
      it "does not raise an error" do
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
        { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
      end
    end

    # context "when query is invalid for update model" do
    #   before do
    #     allow(Utils::QueryValidator).to receive(:validate_query).and_raise(StandardError, "Invalid query")
    #   end

    #   it "renders an error message" do
    #     put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
    #     { "Content-Type": "application/json" }.merge(auth_headers(user))
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.body).to include("Query validation failed: Invalid query")
    #   end
    # end
  end
end
