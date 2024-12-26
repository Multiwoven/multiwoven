# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ModelsController", type: :request do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:connector) do
    create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo")
  end

  let(:source_connector) do
    create(:connector, workspace:, connector_type: "source", name: "DatabricksModel", connector_name: "DatabricksModel")
  end

  let(:connector_without_catalog) do
    create(:connector, workspace:, connector_type: "destination", name: "klavio1", connector_name: "Klaviyo")
  end
  let!(:models) do
    [
      create(:model, connector:, workspace:, name: "model1", query: "SELECT * FROM locations"),
      create(:model, connector:, workspace:, name: "model2", query: "SELECT * FROM locations")
    ]
  end

  let!(:raw_sql_model) { create(:model, query_type: :raw_sql, connector:, workspace:) }
  let!(:dynamic_sql_model) do
    create(:model, query_type: :dynamic_sql, connector:, configuration: { harvesters: [], json_schema: {} }, workspace:)
  end
  let!(:dbt_model) { create(:model, query_type: :dbt, connector:, workspace:) }
  let!(:soql_model) { create(:model, query_type: :soql, connector:, workspace:) }
  let!(:ai_ml_model) do
    create(:model, query_type: :ai_ml, connector:, configuration: { harvesters: [] }, workspace:)
  end
  let!(:ai_ml_source_model) do
    create(:model, query_type: :ai_ml, connector: source_connector, configuration: { harvesters: [] }, workspace:)
  end
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    create(:catalog, connector:)
    create(:catalog, connector: source_connector)
    user.confirm
  end

  describe "GET /api/v1/models" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get "/api/v1/models"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      it "returns success and all model " do
        get "/api/v1/models?page=1&per_page=20", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(8)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1&per_page=20")
      end

      it "returns success and no models when the data is empty" do
        workspace.models.destroy_all
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(0)
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
        expect(response_hash.dig(:links, :last)).to include("http://www.example.com/api/v1/models?page=1")
        expect(response_hash.dig(:links, :next)).to be_nil
        expect(response_hash.dig(:links, :prev)).to be_nil
      end

      it "returns success and all mode for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(8)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
      end

      it "returns success and all model for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(8)
        expect(response_hash.dig(:data, 0, :type)).to eq("models")
        expect(response_hash.dig(:links, :first)).to include("http://www.example.com/api/v1/models?page=1")
      end

      it "filters models based on the query_type parameter" do
        get "/api/v1/models?query_type=data", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_ids = JSON.parse(response.body)["data"].map { |m| m["id"].to_i }
        expect(response_ids).to eq([])
      end

      it "filters models based on the query_type parameter" do
        get "/api/v1/models?query_type=dynamic_sql,ai_ml", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].count).to eql(3)
        response_ids = JSON.parse(response.body)["data"].map { |m| m["id"].to_i }
        expect(response_ids).to match_array([ai_ml_source_model.id, dynamic_sql_model.id, ai_ml_model.id])
      end

      it "filters models based on a different query_type" do
        get "/api/v1/models?query_type=ai_ml", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"].map do |m|
                 m["id"].to_i
               end).to match_array([ai_ml_model.id, ai_ml_source_model.id])
      end

      it "returns all models" do
        get "/api/v1/models", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        model_ids = JSON.parse(response.body)["data"].map { |m| m["id"] }
        expect(model_ids.count).to eql(8)
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

      it "returns success and fetch ai_ml model with configuration from catalog" do
        get "/api/v1/models/#{ai_ml_source_model.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to be_present
        expect(response_hash.dig(:data, :id)).to eq(ai_ml_source_model.id.to_s)
        expect(response_hash.dig(:data, :type)).to eq("models")
        expect(response_hash.dig(:data, :attributes, :name)).to eq(ai_ml_source_model.name)
        expect(response_hash.dig(:data, :attributes, :query)).to eq(ai_ml_source_model.query)
        expect(response_hash.dig(:data, :attributes, :query_type)).to eq(ai_ml_source_model.query_type)
        expect(response_hash.dig(:data, :attributes, :primary_key)).to eq(ai_ml_source_model.primary_key)
        expected_configuration = {
          "harvesters" => [],
          "json_schema" =>
          {
            "input" => [
              { "name" => "inputs.0", "type" => "string", "value" => "dynamic", "value_type" => "dynamic" },
              { "name" => "inputs.0", "type" => "number", "value" => "9522", "value_type" => "static" }
            ],
            "output" => [
              { "name" => "predictions.col1.0", "type" => "string" },
              { "name" => "predictions.col1.1", "type" => "number" }
            ]
          }
        }
        expect(response_hash.dig(:data, :attributes, :configuration)).to eq(expected_configuration)
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
        expect(audit_log.resource).to eq(request_body.dig(:model, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/define/models/#{response_hash['data']['id'].to_i}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "fails model creation for connector without catalog" do
        workspace.workspace_users.first.update(role: member_role)
        # set connector without catalog
        request_body[:model][:connector_id] = connector_without_catalog.id
        # rubocop:disable Rails/SkipsModelValidations
        connector_without_catalog.update_column(:connector_category, "AI Model")
        # rubocop:enable Rails/SkipsModelValidations
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shouldn't fail model creation for connector without catalog for data sources" do
        workspace.workspace_users.first.update(role: member_role)
        request_body[:model][:connector_id] = connector_without_catalog.id
        post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
          .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:created)
      end

      it " creates a new model and returns success" do
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
        expect(audit_log.resource).to eq(request_body.dig(:model, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/define/models/#{response_hash['data']['id'].to_i}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
        expect(audit_log.resource).to eq(request_body.dig(:model, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/define/models/#{response_hash['data']['id'].to_i}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      context "when creating a model with query_type = ai_ml and configuration is present" do
        let(:request_body) do
          {
            model: {
              connector_id: models.first.connector_id,
              name: "AI/ML Model",
              query_type: "ai_ml",
              primary_key: "id",
              configuration: { "harvesters" => [] }
            }
          }
        end

        it "creates the model and returns success" do
          post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
            .merge(auth_headers(user, workspace_id))
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:data, :id)).to be_present
          expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
          expect(response_hash.dig(:data, :attributes, :query_type)).to eq("ai_ml")
          expected_configuration = { "harvesters" => [], "json_schema" => {} }
          expect(response_hash.dig(:data, :attributes, :configuration)).to eq(expected_configuration)

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Model")
          expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
          expect(audit_log.resource).to eq(request_body.dig(:model, :name))
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/define/models/ai/#{response_hash['data']['id'].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end
      end

      context "when creating a model with query_type dynamic_sql with configuration present" do
        let(:request_body) do
          {
            model: {
              connector_id: models.first.connector_id,
              name: "Dynamic SQL Model",
              query_type: "dynamic_sql",
              primary_key: "id",
              configuration:
              {
                "harvesters" => [
                  {
                    "value" => "dynamic test",
                    "method" => "dom",
                    "selector" => "dom_id",
                    "preprocess" => ""
                  }
                ],
                "json_schema" =>
                  {
                    "input" => [
                      {
                        "name" => "risk_level",
                        "type" => "string",
                        "value" => "",
                        "value_type" => "dynamic"
                      }
                    ],
                    "output" => [
                      {
                        "name" => "data.col0.calculated_risk",
                        "type" => "string"
                      }
                    ]
                  }
              }
            }
          }
        end

        it "creates the model and returns success" do
          post "/api/v1/models", params: request_body.to_json, headers: { "Content-Type": "application/json" }
            .merge(auth_headers(user, workspace_id))
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:data, :id)).to be_present
          expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
          expect(response_hash.dig(:data, :attributes, :query_type)).to eq("dynamic_sql")
          expected_configuration = {
            "harvesters" => [
              {
                "value" => "dynamic test",
                "method" => "dom",
                "selector" => "dom_id",
                "preprocess" => ""
              }
            ],
            "json_schema" =>
              {
                "input" => [
                  {
                    "name" => "risk_level",
                    "type" => "string",
                    "value" => "",
                    "value_type" => "dynamic"
                  }
                ],
                "output" => [
                  {
                    "name" => "data.col0.calculated_risk",
                    "type" => "string"
                  }
                ]
              }
          }
          expect(response_hash.dig(:data, :attributes, :configuration)).to eq(expected_configuration)

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Model")
          expect(audit_log.resource_id).to eq(response_hash["data"]["id"].to_i)
          expect(audit_log.resource).to eq(request_body.dig(:model, :name))
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/define/models/#{response_hash['data']['id'].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(models.second.id)
        expect(audit_log.resource).to eq(request_body.dig(:model, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/define/models/#{models.second.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "fails model update for connector without catalog for ai model" do
        workspace.workspace_users.first.update(role: member_role)
        model = models.second
        model.connector_id = connector_without_catalog.id
        model.save!
        # rubocop:disable Rails/SkipsModelValidations
        connector_without_catalog.update_column(:connector_category, "AI Model")
        # rubocop:enable Rails/SkipsModelValidations

        put "/api/v1/models/#{models.second.id}", params: request_body.to_json,
                                                  headers: { "Content-Type": "application/json" }
                                                    .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "shouldn't fail model update for connector without catalog for data connector" do
        workspace.workspace_users.first.update(role: member_role)
        model = models.second
        model.connector_id = connector_without_catalog.id
        model.save!
        put "/api/v1/models/#{models.second.id}", params: request_body.to_json,
                                                  headers: { "Content-Type": "application/json" }
                                                    .merge(auth_headers(user, workspace_id))
        expect(response).to have_http_status(:ok)
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(models.second.id)
        expect(audit_log.resource).to eq(request_body.dig(:model, :name))
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.resource_link).to eq("/define/models/#{models.second.id}")
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      context "when updating a model with query_type = ai_ml and configuration is present" do
        let(:request_body) do
          {
            model: {
              connector_id: models.first.connector_id,
              name: "Updated AI/ML Model",
              query_type: "ai_ml",
              primary_key: "updated_id",
              configuration: { "harvesters" => [] }
            }
          }
        end
        it "updates the model and returns success" do
          put "/api/v1/models/#{models.second.id}", params: request_body.to_json, headers:
            { "Content-Type": "application/json" }.merge(auth_headers(user, workspace_id))
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:data, :id)).to be_present
          expect(response_hash.dig(:data, :id)).to eq(models.second.id.to_s)
          expect(response_hash.dig(:data, :attributes, :name)).to eq(request_body.dig(:model, :name))
          expect(response_hash.dig(:data, :attributes, :query_type)).to eq("ai_ml")
          expected_configuration = { "harvesters" => [], "json_schema" => {} }
          expect(response_hash.dig(:data, :attributes, :configuration)).to eq(expected_configuration)

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("update")
          expect(audit_log.resource_type).to eq("Model")
          expect(audit_log.resource_id).to eq(models.second.id)
          expect(audit_log.resource).to eq(request_body.dig(:model, :name))
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/define/models/ai/#{models.second.id}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end
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

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(models.first.id)
        expect(audit_log.resource).to eq(models.first.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns success and delete model for member role" do
        workspace.workspace_users.first.update(role: member_role)
        delete "/api/v1/models/#{models.first.id}", headers: auth_headers(user, workspace_id)
        expect(response).to have_http_status(:no_content)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("delete")
        expect(audit_log.resource_type).to eq("Model")
        expect(audit_log.resource_id).to eq(models.first.id)
        expect(audit_log.resource).to eq(models.first.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
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
