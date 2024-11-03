# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::DataAppsController, type: :controller do
  let(:client) { Multiwoven::Integrations::Source::DatabricksModel::Client.new }
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
  let!(:ai_ml_connector) do
    create(:connector, connector_name: "DatabricksModel", workspace:, connector_type: "source",
                       connector_category: "AI Model")
  end
  let!(:ai_ml_model) do
    create(:model, query_type: :ai_ml, connector: ai_ml_connector, configuration: { key: "value" }, workspace:)
  end

  let!(:catalog) do
    create(
      :catalog,
      connector: ai_ml_connector,
      workspace:,
      catalog: {
        "streams" => [
          {
            "url" => "unknown",
            "name" => "DatabricksModel",
            "batch_size" => 0,
            "json_schema" => {
              "input" => [
                { "name" => "messages.0.role", "type" => "string", "value" => "key1", "value_type" => "dynamic" },
                { "name" => "messages.0.content", "type" => "string", "value" => "key2", "value_type" => "dynamic" },
                { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" },
                { "name" => "messages.0.new.id", "type" => "number", "value" => "1", "value_type" => "static" }
              ],
              "output" => [
                { "name" => "messages.0.role", "type" => "string" },
                { "name" => "messages.0.role", "type" => "string" }
              ]
            },
            "batch_support" => false,
            "request_method" => "POST"
          }
        ],
        "request_rate_limit" => 600,
        "request_rate_limit_unit" => "minute",
        "request_rate_concurrency" => 10
      },
      catalog_hash: "3688ef805acee1912a6f54e4c622c17ef11f5fc5"
    )
  end

  let(:visual_component) { create(:visual_component, data_app:, workspace:, model: ai_ml_model) }

  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    user.confirm
    request.headers.merge!(auth_headers(user, workspace.id))
    create(:catalog, connector: ai_ml_connector, workspace:)
  end

  describe "GET /enterprise/api/v1/data_apps" do
    context "when authenticated" do
      it "returns a paginated list of data apps admin role" do
        create_list(:data_app, 3, workspace:)

        get :index, params: { page: 1 }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:data, 0, :attributes, :data_app_token)).not_to be_nil
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("index")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(nil)
        expect(audit_log.resource).to eq(nil)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns a paginated list of data apps member role" do
        workspace.workspace_users.first.update(role: member_role)
        create_list(:data_app, 3, workspace:)

        get :index, params: { page: 1 }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:data, 0, :attributes, :created_at)).not_to be_nil
        expect(response_hash.dig(:data, 0, :attributes, :updated_at)).not_to be_nil
        expect(response_hash.dig(:data, 0, :attributes, :data_app_token)).not_to be_nil
        first_row_date = DateTime.parse(response_hash[:data].first.dig(:attributes, :created_at))
        second_row_date = DateTime.parse(response_hash[:data].last.dig(:attributes, :created_at))
        expect(first_row_date).to be > second_row_date
        visual_components = response_hash.dig(:data, 3, :attributes, :visual_components)
        expect(visual_components.dig(0, :created_at)).not_to be_nil
        expect(visual_components.dig(0, :updated_at)).not_to be_nil
        expect(visual_components.dig(0, :model, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :model, :connector, :icon))
          .to eq(data_app.visual_components.first.model.connector.icon)
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("index")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(nil)
        expect(audit_log.resource).to eq(nil)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns a paginated list of data apps viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        create_list(:data_app, 3, workspace:)

        get :index, params: { page: 1 }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, 0, :attributes, :data_app_token)).not_to be_nil
        expect(response_hash[:data].size).to eq(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("index")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(nil)
        expect(audit_log.resource).to eq(nil)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns a paginated list ordered by updated_at" do
        create_list(:data_app, 3, workspace:)
        workspace.data_apps[0].update(updated_at: Time.current + 1.day)

        get :index, params: { page: 1 }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:data, 0, :attributes, :created_at)).not_to be_nil
        expect(response_hash.dig(:data, 0, :attributes, :updated_at)).not_to be_nil
        expect(response_hash.dig(:data, 0, :attributes, :data_app_token)).not_to be_nil
        first_row_date = DateTime.parse(response_hash[:data].first.dig(:attributes, :updated_at))
        second_row_date = DateTime.parse(response_hash[:data].last.dig(:attributes, :updated_at))
        expect(first_row_date).to be > second_row_date
      end
    end

    context "when unauthenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /enterprise/api/v1/data_apps/:id" do
    context "when authenticated" do
      it "returns the data app admin role" do
        get :show, params: { id: data_app.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to eq(data_app.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(data_app.name)
        expect(response_hash.dig(:data, :attributes, :description)).to eq(data_app.description)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(data_app.status)
        expect(response_hash.dig(:data, :attributes, :created_at)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :updated_at)).not_to be_nil
        expect(response_hash.dig(:data, :attributes, :data_app_token)).not_to be_nil
        visual_components = response_hash.dig(:data, :attributes, :visual_components)
        expect(visual_components.dig(0, :component_type)).to eq(data_app.visual_components.first.component_type)
        expect(visual_components.dig(0, :model, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :model, :connector, :icon))
          .to eq(data_app.visual_components.first.model.connector.icon)
        expect(visual_components.dig(0, :created_at)).not_to be_nil
        expect(visual_components.dig(0, :updated_at)).not_to be_nil

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("show")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app.id)
        expect(audit_log.resource).to eq(data_app.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns the data app member role" do
        workspace.workspace_users.first.update(role: member_role)
        get :show, params: { id: data_app.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to eq(data_app.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(data_app.name)
        expect(response_hash.dig(:data, :attributes, :description)).to eq(data_app.description)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(data_app.status)
        expect(response_hash.dig(:data, :attributes, :data_app_token)).not_to be_nil
        visual_components = response_hash.dig(:data, :attributes, :visual_components)
        expect(visual_components.dig(0, :component_type)).to eq(data_app.visual_components.first.component_type)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("show")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app.id)
        expect(audit_log.resource).to eq(data_app.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns the data app viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get :show, params: { id: data_app.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:data, :id)).to eq(data_app.id.to_s)
        expect(response_hash.dig(:data, :attributes, :name)).to eq(data_app.name)
        expect(response_hash.dig(:data, :attributes, :description)).to eq(data_app.description)
        expect(response_hash.dig(:data, :attributes, :status)).to eq(data_app.status)
        expect(response_hash.dig(:data, :attributes, :data_app_token)).not_to be_nil
        visual_components = response_hash.dig(:data, :attributes, :visual_components)
        expect(visual_components.dig(0, :component_type)).to eq(data_app.visual_components.first.component_type)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("show")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app.id)
        expect(audit_log.resource).to eq(data_app.name)
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "returns bad for a invalid id" do
        get :show, params: { id: "non-existant" }
        expect(response).to have_http_status(:bad_request)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors][0][:detail]).to eq("id must be an integer")
      end

      it "returns not found for a non-existent data app" do
        get :show, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end

      context "when authenticated with data app token" do
        before do
          request.headers["Authorization"] = nil
          request.headers["Data-App-Id"] = data_app.id.to_s
          request.headers["Data-App-Token"] = data_app.data_app_token
        end
        it "returns the data app admin role" do
          get :show, params: { id: data_app.id }
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:data, :id)).to eq(data_app.id.to_s)
          expect(response_hash.dig(:data, :attributes, :name)).to eq(data_app.name)
          expect(response_hash.dig(:data, :attributes, :description)).to eq(data_app.description)
          expect(response_hash.dig(:data, :attributes, :status)).to eq(data_app.status)
          expect(response_hash.dig(:data, :attributes, :created_at)).not_to be_nil
          expect(response_hash.dig(:data, :attributes, :updated_at)).not_to be_nil
          expect(response_hash.dig(:data, :attributes, :data_app_token)).not_to be_nil
        end
      end
    end

    context "when unauthenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized" do
        get :show, params: { id: data_app.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /enterprise/api/v1/data_apps" do
    context "when authenticated" do
      context "with valid params" do
        let(:valid_params) do
          {
            data_app: {
              name: "Data Apps name",
              description: "",

              meta_data: {
                rendering_type: "embed"
              },
              visual_components: [
                {
                  component_type: "doughnut",
                  model_id: ai_ml_model.id,
                  properties: { color: "blue" },
                  feedback_config: { enabled: true }
                }
              ]
            }
          }
        end

        it "creates a new data app and returns success - admin role" do
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data]).to be_present

          data_app = response_hash[:data]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          attributes = data_app[:attributes]
          expect(attributes[:name]).to eq(valid_params[:data_app][:name])
          expect(attributes[:description]).to eq(valid_params[:data_app][:description])
          expect(attributes[:status]).to eq("draft")
          expect(attributes[:visual_components]).to be_present
          visual_component = attributes[:visual_components].first
          expect(visual_component[:id]).to be_present
          expect(visual_component[:component_type]).to eq("doughnut")
          expect(attributes[:data_app_token]).to be_present

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(nil)
          expect(audit_log.resource).to eq(data_app[:attributes][:name])
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "creates a new data app and returns success - member role" do
          workspace.workspace_users.first.update(role: member_role)
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          data_app = response_hash[:data]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          attributes = data_app[:attributes]
          expect(attributes[:name]).to eq(valid_params[:data_app][:name])
          expect(attributes[:description]).to eq(valid_params[:data_app][:description])
          expect(attributes[:status]).to eq("draft")
          expect(attributes[:visual_components]).to be_present
          expect(attributes[:data_app_token]).to be_present

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(nil)
          expect(audit_log.resource).to eq(data_app[:attributes][:name])
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "creates a new data app and returns success - viewer role" do
          workspace.workspace_users.first.update(role: viewer_role)
          post :create, params: valid_params
          expect(response).to have_http_status(:unauthorized)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to eq("You are not authorized to do this action")
        end
      end

      context "with invalid params" do
        let(:invalid_params) do
          {
            data_app: {
              name: "",
              description: "Invalid data app",
              status: "inactive",
              visual_components: []
            }
          }
        end

        it "returns unprocessable entity" do
          post :create, params: invalid_params
          expect(response).to have_http_status(:bad_request)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to include("name must be filled")
        end
      end
    end

    context "when unauthenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized" do
        post :create, params: { data_app: { name: "Unauthenticated App" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT /enterprise/api/v1/data_apps/:id" do
    context "when authenticated" do
      context "with valid params" do
        let(:valid_update_params) do
          {
            data_app: {
              name: "Updated Sales Dashboard",
              description: "An updated dashboard for sales",
              status: "inactive",
              meta_data: {
                author: "John Doe",
                version: "2.0"
              },
              visual_components: [
                {
                  id: visual_component.id,
                  component_type: "bar",
                  model_id: ai_ml_model.id,
                  properties: { color: "red" },
                  feedback_config: { enabled: false }
                }
              ]
            }
          }
        end

        it "updates the data app and returns success - admin role" do
          put :update, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(data_app.reload.name).to eq("Updated Sales Dashboard")
          expect(visual_component.reload.component_type).to eq("bar")
          data_app = response_hash[:data]
          attributes = data_app[:attributes]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          expect(attributes[:data_app_token]).to be_present

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("update")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq("Updated Sales Dashboard")
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "updates the data app and returns success - member role" do
          workspace.workspace_users.first.update(role: member_role)
          put :update, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(data_app.reload.name).to eq("Updated Sales Dashboard")
          expect(visual_component.reload.component_type).to eq("bar")
          data_app = response_hash[:data]
          attributes = data_app[:attributes]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          expect(attributes[:data_app_token]).to be_present

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("update")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq("Updated Sales Dashboard")
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "returns unauthorized for viewer role" do
          workspace.workspace_users.first.update(role: viewer_role)
          put :update, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:unauthorized)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to eq("You are not authorized to do this action")
        end
      end

      context "with invalid params" do
        let(:invalid_update_params) do
          {
            data_app: {
              name: "",
              description: "An invalid update",
              status: "inactive1",
              visual_components: []
            }
          }
        end

        it "returns unprocessable entity" do
          put :update, params: invalid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:bad_request)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to include("status invalid")
        end
      end
    end

    context "when unauthenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized" do
        put :update, params: { id: data_app.id, data_app: { name: "Unauthorized Update" } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid params insert new visual_component" do
      let(:existing_visual_component) { create(:visual_component, data_app:) }

      let(:valid_update_params_with_new_component) do
        {
          data_app: {
            name: "Updated Sales Dashboard",
            description: "An updated dashboard for sales",
            status: "inactive",
            meta_data: {
              author: "John Doe",
              version: "2.0"
            },
            visual_components: [
              {
                id: existing_visual_component.id,
                component_type: "bar",
                name: "Updated Sales Chart",
                model_id: ai_ml_model.id,
                properties: { color: "red" },
                feedback_config: { enabled: false }
              },
              {
                component_type: "doughnut",
                model_id: ai_ml_model.id,
                properties: { color: "blue" },
                feedback_config: { enabled: true }
              }
            ]
          }
        }
      end

      it "inserts a new visual component" do
        put :update, params: valid_update_params_with_new_component.merge(id: data_app.id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(data_app.reload.visual_components.count).to eq(2) # Ensure 2 components after update
        expect(data_app.visual_components.last.component_type).to eq("doughnut")
        expect(data_app.visual_components.last.name).to be_nil
        data_app = response_hash[:data]
        attributes = data_app[:attributes]
        expect(data_app[:id]).to be_present
        expect(data_app[:type]).to eq("data_apps")
        expect(attributes[:data_app_token]).to be_present

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app[:id].to_i)
        expect(audit_log.resource).to eq("Updated Sales Dashboard")
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "with valid params remove visual_component" do
      let(:existing_visual_component) { create(:visual_component, data_app:) }

      let(:valid_update_params_with_remove) do
        {
          data_app: {
            name: "Updated Sales Dashboard",
            description: "An updated dashboard for sales",
            status: "inactive",
            meta_data: {
              author: "John Doe",
              version: "2.0"
            },
            visual_components: [
              {
                id: existing_visual_component.id,
                component_type: "bar",
                name: "Updated Sales Chart",
                model_id: ai_ml_model.id,
                properties: { color: "red" },
                feedback_config: { enabled: false }
              }
            ]
          }
        }
      end

      it "removes a visual component" do
        # Create an extra component to be removed
        extra_component = create(:visual_component, data_app:)
        put :update, params: valid_update_params_with_remove.merge(id: data_app.id)
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(data_app.reload.visual_components.count).to eq(1) # Ensure only 1 component after update
        expect(data_app.visual_components).to include(existing_visual_component)
        expect(data_app.visual_components).not_to include(extra_component)
        data_app = response_hash[:data]
        attributes = data_app[:attributes]
        expect(data_app[:id]).to be_present
        expect(data_app[:type]).to eq("data_apps")
        expect(attributes[:data_app_token]).to be_present

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("update")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app[:id].to_i)
        expect(audit_log.resource).to eq(valid_update_params_with_remove[:data_app][:name])
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end
  end

  describe "DELETE /enterprise/api/v1/data_apps/:id" do
    context "when authenticated" do
      it "deletes the data app and returns no content - admin role" do
        visual_component = data_app.visual_components.first
        expect(visual_component).not_to be_nil
        delete :destroy, params: { id: data_app.id }
        expect(response).to have_http_status(:no_content)
        expect { visual_component.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { data_app.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "deletes the data app and returns no content - member role" do
        workspace.workspace_users.first.update(role: member_role)
        visual_component = data_app.visual_components.first
        expect(visual_component).not_to be_nil
        delete :destroy, params: { id: data_app.id }
        expect(response).to have_http_status(:no_content)
        expect { visual_component.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { data_app.reload }.to raise_error(ActiveRecord::RecordNotFound)

        audit_log = AuditLog.last
        expect(audit_log).not_to be_nil
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("destroy")
        expect(audit_log.resource_type).to eq("Data_app")
        expect(audit_log.resource_id).to eq(data_app[:id].to_i)
        expect(audit_log.resource).to eq(data_app[:name])
        expect(audit_log.workspace_id).to eq(workspace.id)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end

      it "deletes the data app and returns no content - viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        delete :destroy, params: { id: data_app.id }
        expect(response).to have_http_status(:unauthorized)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash.dig(:errors, 0, :detail)).to eq("You are not authorized to do this action")
      end

      it "returns not found for a non-existent data app" do
        delete :destroy, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized" do
        delete :destroy, params: { id: data_app.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /enterprise/api/v1/data_apps/:id/fetch_data" do
    let!(:session) { create(:data_app_session, data_app:, session_id: "session_1") }
    let(:valid_fetch_params) do
      {
        fetch_data: {
          session_id: session.session_id,
          visual_components: [
            {
              visual_component_id: visual_component.id,
              harvest_values: {
                "key1" => "value1",
                "key2" => "value2"
              }
            }
          ]
        }
      }
    end
    context "when authenticated" do
      let(:record) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                      "first_name" => "John", "Last Name" => "Doe" },
                                                              emitted_at: DateTime.now.to_i).to_multiwoven_message
      end

      before do
        allow(visual_component.model.connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_return([record])
      end

      context "with data app token" do
        it "fetches data from the model and returns success (admin role)" do
          post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)

          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data_app]).not_to be_nil
          expect(response_hash[:data_app][:results].first).to include(
            data: {
              "id" => 1,
              "email" => "test1@mail.com",
              "first_name" => "John",
              "Last Name" => "Doe"
            },
            errors: nil
          )
        end
      end

      context "with data app token" do
        before do
          request.headers["Authorization"] = nil
          request.headers["Data-App-Id"] = data_app.id.to_s
          request.headers["Data-App-Token"] = data_app.data_app_token
        end

        it "fetches data from the model and returns success" do
          post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)

          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data_app]).not_to be_nil
          expect(response_hash[:data_app][:results].first).to include(
            data: {
              "id" => 1,
              "email" => "test1@mail.com",
              "first_name" => "John",
              "Last Name" => "Doe"
            },
            errors: nil
          )
        end
      end
    end

    context "with invalid params" do
      let(:invalid_fetch_params) do
        {
          fetch_data: {
            session_id: "test213e3",
            visual_components: [
              {
                visual_component_id: 100_923, # Invalid ID
                harvest_values: {}
              }
            ]
          }
        }
      end

      it "returns a not found error" do
        post :fetch_data, params: invalid_fetch_params.merge(id: data_app.id)
        expect(response).to have_http_status(:unprocessable_entity)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first).to include(
          "detail" => "Data Fetch Failed: Visual Component not found",
          "source" => "Visual Component not found",
          "status" => 422,
          "title" => "Error"
        )
      end
    end

    context "when no data is found" do
      before do
        allow(visual_component.model.connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_return([nil]) # Simulating no data found
      end

      it "returns an error message" do
        post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
        expect(response).to have_http_status(:unprocessable_entity)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first).to include(
          "detail" => "Data Fetch Failed: No data found",
          "source" => "No data found",
          "status" => 422,
          "title" => "Error"
        )
      end

      context "session handling" do
        let(:record) do
          Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                        "first_name" => "John", "Last Name" => "Doe" },
                                                                emitted_at: DateTime.now.to_i).to_multiwoven_message
        end

        before do
          allow(visual_component.model.connector.connector_client).to receive(:new).and_return(client)
          allow(client).to receive(:read).and_return([record])
        end
        context "when a session exists" do
          it "fetches data without creating a new session" do
            initial_session_count = data_app.data_app_sessions.count
            post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
            expect(response).to have_http_status(:ok)
            expect(data_app.data_app_sessions.count).to eq(initial_session_count)
          end
        end

        context "when no session exists" do
          it "creates a new session" do
            initial_session_count = data_app.data_app_sessions.count
            modified_fetch_params = valid_fetch_params.deep_merge(fetch_data: { session_id: "new_session_id" })
            post :fetch_data, params: modified_fetch_params.merge(id: data_app.id)
            expect(response).to have_http_status(:ok)
            expect(data_app.data_app_sessions.count).to eq(initial_session_count + 1)
          end
        end

        context "when the session is expired" do
          before do
            session.update(end_time: 1.minute.ago) # Simulate an expired session
          end
          it "returns an unauthorized error" do
            post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
            expect(response).to have_http_status(:unauthorized)
            response_hash = JSON.parse(response.body).with_indifferent_access
            expect(response_hash[:errors].first[:detail])
              .to eq("Session session_1 has expired. Please start a new session.")
          end
        end
      end
    end

    context "when an exception is raised during fetching" do
      before do
        allow(visual_component.model.connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_raise(StandardError, "Some error occurred") # Simulate an error
      end

      it "returns an error message" do
        post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
        expect(response).to have_http_status(:unprocessable_entity)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first).to include(
          "detail" => "Data Fetch Failed: Some error occurred",
          "source" => "Some error occurred",
          "status" => 422,
          "title" => "Error"
        )
      end
    end
  end
end
