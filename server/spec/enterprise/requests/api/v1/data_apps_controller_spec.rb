# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::DataAppsController, type: :controller do
  include Concerns::DataApps::FetchDataHelpers

  let(:client) { Multiwoven::Integrations::Source::DatabricksModel::Client.new }
  let(:dsql_client) { Multiwoven::Integrations::Source::Postgresql::Client.new }
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
  let!(:ai_ml_connector) do
    create(:connector, connector_name: "DatabricksModel", workspace:, connector_type: "source",
                       connector_category: "AI Model")
  end
  let!(:ai_ml_model) do
    create(:model, query_type: :ai_ml, connector: ai_ml_connector, configuration: { harvesters: [] }, workspace:)
  end

  let!(:dsql_connector) do
    create(:connector, connector_name: "Postgresql", connector_type: "source", connector_category: "Dynamic SQL")
  end

  let!(:dynamic_sql_model) do
    create(:model, query_type: :dynamic_sql, connector: dsql_connector,
                   configuration: {
                     json_schema: {
                       input: [{ "name" => "name",
                                 "type" => "string", "value" => "", "value_type" => "dynamic" },
                               { "name" => "age",
                                 "type" => "number", "value" => "22", "value_type" => "static" },
                               { "name" => "gender",
                                 "type" => "string", "value" => "", "value_type" => "dynamic" }],
                       output: []
                     },
                     harvesters: []
                   },
                   query: "SELECT * FROM public.actor WHERE name=':name' AND age=:age AND gender=':gender'")
  end

  let!(:workflow) { create(:workflow, workspace:) }

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
                { "name" => "messages.0.test", "type" => "string", "value" => "hai", "value_type" => "static" }
              ],
              "output" => [{ "name" => "response", "type": "string" }]
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

  let(:visual_component) { create(:visual_component, data_app:, workspace:, configurable: ai_ml_model) }
  let(:visual_component_dsql) { create(:visual_component, data_app:, workspace:, configurable: dynamic_sql_model) }
  let(:workflow_visual_component) do
    create(:visual_component, data_app:, workspace:, configurable: workflow, component_type: "chat_bot")
  end

  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  let(:chat_message_user) do
    create(:chat_message, session:, role: "user",
                          content: "User message", workspace:, visual_component:)
  end
  let(:chat_message_assistant) do
    create(:chat_message, session:, role: "assistant", content: "Assistant message",
                          workspace:, visual_component:)
  end

  before do
    user.confirm
    request.headers.merge!(auth_headers(user, workspace.id))
  end

  describe "GET /enterprise/api/v1/data_apps" do
    context "when authenticated" do
      it "returns a paginated list of data apps admin role" do
        create_list(:data_app, 3, workspace:)

        get :index, params: { page: 1, per_page: 3 }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(3)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:data, 0, :attributes, :data_app_token)).not_to be_nil
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=3")
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
        expect(visual_components.dig(0, :configurable, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :configurable, :connector, :icon))
          .to eq(data_app.visual_components.first.model.connector.icon)
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")
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

      it "returns a paginated list of data apps by filtered render_type" do
        workspace.workspace_users.first.update(role: viewer_role)
        create(:data_app, workspace:, rendering_type: "no_code")

        get :index, params: { page: 1, rendering_type: "no_code" }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(1)
      end
    end

    context "with configurable_type params" do
      before do
        DataApp.delete_all
      end
      let!(:data_app_model) { create(:data_app, workspace:, visual_components_count: 0) }
      let!(:visual_component_model) do
        create(:visual_component, data_app: data_app_model, workspace:, configurable: ai_ml_model)
      end

      let!(:data_app_workflow) { create(:data_app, workspace:, visual_components_count: 0) }
      let!(:visual_component_workflow) do
        create(:visual_component, data_app: data_app_workflow, workspace:, configurable: workflow)
      end

      it "filters data apps by configurable default both" do
        get :index, params: { page: 1 }

        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(2)

        expect(
          response_hash.dig(:data, 0, :attributes, :visual_components, 0, :configurable, :name)
        ).to include(workflow.name)
        expect(
          response_hash.dig(:data, 1, :attributes, :visual_components, 0, :configurable, :name)
        ).to include(ai_ml_model.name)
      end

      it "filters data apps by configurable_type=model" do
        get :index, params: { page: 1, configurable_type: "model" }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(1)
        expect(
          response_hash.dig(:data, 0, :attributes, :visual_components, 0, :configurable, :name)
        ).to include(ai_ml_model.name)
      end

      it "filters data apps by configurable_type=workflow" do
        get :index, params: { page: 1, configurable_type: "workflow" }
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data].size).to eq(1)
        expect(
          response_hash.dig(:data, 0, :attributes, :visual_components, 0, :configurable, :name)
        ).to include(workflow.name)
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
        expect(visual_components.dig(0, :configurable, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :configurable, :connector, :icon))
          .to eq(data_app.visual_components.first.model.connector.icon)
        expect(visual_components.dig(0, :created_at)).not_to be_nil
        expect(visual_components.dig(0, :updated_at)).not_to be_nil
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
      end

      it "returns bad for a invalid id" do
        get :show, params: { id: "non-existent" }
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
              rendering_type: "embed",
              meta_data: {
                rendering_type: "embed"
              },
              visual_components: [
                {
                  component_type: "doughnut",
                  configurable_id: ai_ml_model.id,
                  configurable_type: "model",
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
          expect(attributes[:rendering_type]).to eq("embed")
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
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq(data_app[:attributes][:name])
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
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
          expect(attributes[:rendering_type]).to eq("embed")
          expect(attributes[:visual_components]).to be_present
          expect(attributes[:data_app_token]).to be_present

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq(data_app[:attributes][:name])
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "creates a new data app and returns success - viewer role" do
          workspace.workspace_users.first.update(role: viewer_role)
          post :create, params: valid_params
          expect(response).to have_http_status(:forbidden)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to eq("You are not authorized to do this action")
        end
      end

      context "with workflow-based visual components" do
        let(:valid_workflow_params) do
          {
            data_app: {
              name: "Workflow Data App",
              description: "A data app with workflow configurable",
              rendering_type: "embed",
              meta_data: {
                rendering_type: "embed"
              },
              visual_components: [
                {
                  component_type: "chat_bot",
                  configurable_id: workflow.id.to_s,
                  configurable_type: "workflow",
                  properties: { theme: "dark" },
                  feedback_config: { enabled: true }
                }
              ]
            }
          }
        end

        it "creates a new data app with workflow configurable - admin role" do
          post :create, params: valid_workflow_params
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data]).to be_present

          data_app = response_hash[:data]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          attributes = data_app[:attributes]
          expect(attributes[:name]).to eq(valid_workflow_params[:data_app][:name])
          expect(attributes[:description]).to eq(valid_workflow_params[:data_app][:description])
          expect(attributes[:status]).to eq("draft")
          expect(attributes[:rendering_type]).to eq("embed")
          expect(attributes[:visual_components]).to be_present
          visual_component = attributes[:visual_components].first
          expect(visual_component[:id]).to be_present
          expect(visual_component[:component_type]).to eq("chat_bot")
          expect(visual_component[:configurable_type]).to eq("workflow")
          expect(visual_component[:configurable_id]).to eq(workflow.id.to_s)
          expect(attributes[:data_app_token]).to be_present

          # Verify the created visual component has correct workflow association
          created_data_app = DataApp.find(data_app[:id])
          created_visual_component = created_data_app.visual_components.first
          expect(created_visual_component.workflow).to eq(workflow)
          expect(created_visual_component.model).to be_nil
          expect(created_visual_component.configurable_type).to eq("Agents::Workflow")

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("create")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq(data_app[:attributes][:name])
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
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
              rendering_type: "embed",
              meta_data: {
                author: "John Doe",
                version: "2.0"
              },
              visual_components: [
                {
                  id: visual_component.id,
                  component_type: "bar",
                  configurable_id: ai_ml_model.id,
                  configurable_type: "model",
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
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
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
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        it "returns unauthorized for viewer role" do
          workspace.workspace_users.first.update(role: viewer_role)
          put :update, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:forbidden)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash.dig(:errors, 0, :detail)).to eq("You are not authorized to do this action")
        end
      end

      context "with workflow-based visual components" do
        let!(:workflow_data_app) { create(:data_app, workspace:) }
        let!(:workflow_visual_component) do
          create(:visual_component, data_app: workflow_data_app, workspace:, configurable: workflow,
                                    component_type: "chat_bot")
        end

        let(:valid_workflow_update_params) do
          {
            data_app: {
              name: "Updated Workflow Dashboard",
              description: "An updated dashboard with workflow configurable",
              status: "active",
              rendering_type: "embed",
              meta_data: {
                author: "Jane Doe",
                version: "3.0"
              },
              visual_components: [
                {
                  id: workflow_visual_component.id,
                  component_type: "chat_bot",
                  configurable_id: workflow.id.to_s,
                  configurable_type: "workflow",
                  properties: { theme: "light" },
                  feedback_config: { enabled: true }
                }
              ]
            }
          }
        end

        it "updates the data app with workflow configurable - admin role" do
          put :update, params: valid_workflow_update_params.merge(id: workflow_data_app.id)
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(workflow_data_app.reload.name).to eq("Updated Workflow Dashboard")
          expect(workflow_visual_component.reload.component_type).to eq("chat_bot")
          data_app = response_hash[:data]
          attributes = data_app[:attributes]
          expect(data_app[:id]).to be_present
          expect(data_app[:type]).to eq("data_apps")
          expect(attributes[:data_app_token]).to be_present

          # Verify the updated visual component has correct workflow association
          expect(workflow_visual_component.reload.workflow).to eq(workflow)
          expect(workflow_visual_component.reload.model).to be_nil
          expect(workflow_visual_component.reload.configurable_type).to eq("Agents::Workflow")

          audit_log = AuditLog.last
          expect(audit_log).not_to be_nil
          expect(audit_log.user_id).to eq(user.id)
          expect(audit_log.action).to eq("update")
          expect(audit_log.resource_type).to eq("Data_app")
          expect(audit_log.resource_id).to eq(data_app[:id].to_i)
          expect(audit_log.resource).to eq("Updated Workflow Dashboard")
          expect(audit_log.workspace_id).to eq(workspace.id)
          expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
          expect(audit_log.created_at).not_to be_nil
          expect(audit_log.updated_at).not_to be_nil
        end

        context "with invalid workflow configurable_id" do
          let(:invalid_workflow_update_params) do
            {
              data_app: {
                name: "Invalid Workflow Update",
                description: "An invalid update with workflow configurable",
                status: "active",
                rendering_type: "embed",
                meta_data: {
                  author: "Jane Doe",
                  version: "3.0"
                },
                visual_components: [
                  {
                    id: workflow_visual_component.id,
                    component_type: "chat_bot",
                    configurable_id: "invalid-uuid",
                    configurable_type: "workflow",
                    properties: { theme: "light" },
                    feedback_config: { enabled: true }
                  }
                ]
              }
            }
          end

          it "returns bad request for invalid workflow configurable_id" do
            put :update, params: invalid_workflow_update_params.merge(id: workflow_data_app.id)
            expect(response).to have_http_status(:bad_request)
            response_hash = JSON.parse(response.body).with_indifferent_access
            expect(response_hash.dig(:errors, 0,
                                     :detail)).to include("configurable_id must be a valid UUID for workflow type")
          end
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
            rendering_type: "embed",
            meta_data: {
              author: "John Doe",
              version: "2.0"
            },
            visual_components: [
              {
                id: existing_visual_component.id,
                component_type: "bar",
                name: "Updated Sales Chart",
                configurable_id: ai_ml_model.id,
                configurable_type: "model",
                properties: { color: "red" },
                feedback_config: { enabled: false }
              },
              {
                component_type: "doughnut",
                configurable_id: ai_ml_model.id,
                configurable_type: "model",
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
        expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
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
            rendering_type: "embed",
            meta_data: {
              author: "John Doe",
              version: "2.0"
            },
            visual_components: [
              {
                id: existing_visual_component.id,
                component_type: "bar",
                name: "Updated Sales Chart",
                configurable_id: ai_ml_model.id,
                configurable_type: "model",
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
        expect(audit_log.resource_link).to eq("/data-apps/list/#{data_app[:id].to_i}")
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
        expect(audit_log.action).to eq("delete")
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
        expect(response).to have_http_status(:forbidden)
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

  describe "POST /enterprise/api/v1/data_apps/:id/fetch_data" do
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
    let(:valid_fetch_params_dynamic_sql) do
      {
        fetch_data: {
          session_id: session.session_id,
          visual_components: [
            {
              visual_component_id: visual_component_dsql.id,
              harvest_values: { "name" => "first_name", "gender" => "female" }
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

        allow(visual_component_dsql.model.connector.connector_client).to receive(:new).and_return(dsql_client)
        allow(dsql_client).to receive(:read).and_return([record])
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

      context "with chatbot harvesting value one" do
        let(:valid_fetch_params) do
          {
            fetch_data: {
              session_id: session.session_id,
              visual_components: [
                {
                  visual_component_id: visual_component.id,
                  harvest_values: {
                    "key1" => "value1"
                  }
                }
              ]
            }
          }
        end

        let(:record) do
          Multiwoven::Integrations::Protocol::RecordMessage.new(
            data: {
              "model" => "llama3.2", "created_at" => "2024-12-13T12:49:16.349172Z", "response" => "hello"
            },
            emitted_at: DateTime.now.to_i
          ).to_multiwoven_message
        end
        let(:payload) do
          "{\"messages\":[{\"role\":\"This is an ongoing conversation between a user and an AI assistant. "\
          "The assistant should provide helpful, relevant responses directly to the user's query in a "\
          "natural and conversational manner.\\n\\n" \
          "Conversation History:\\n"\
          "User: User message\\n" \
          "Assistant: Assistant message\\n\\n" \
          "User's Query:\\nvalue1\\n\\n\\n"\
          "Please respond directly to the user's query.\",\"test\":\"hai\"}]}"
        end

        let(:sync_config) { build_sync_config(visual_component.model, payload) }

        before do
          chat_message_user
          chat_message_assistant
          visual_component.update(component_type: "chat_bot")
          request.headers["Authorization"] = nil
          request.headers["Data-App-Id"] = data_app.id.to_s
          request.headers["Data-App-Token"] = data_app.data_app_token

          allow_any_instance_of(visual_component.model.connector.connector_client)
            .to receive(:read).with(sync_config).and_return([record])
        end

        it "fetches data from the model and returns success" do
          post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data_app]).not_to be_nil
          expect(response_hash[:data_app][:results].first).to include(
            data: {
              "created_at" => "2024-12-13T12:49:16.349172Z",
              "model" => "llama3.2",
              "response" => "hello"
            },
            errors: nil
          )
          expect(session.chat_messages.count).to eq(4)
          expect(session.chat_messages.last.content).to eq("hello")
          expect(session.chat_messages[-2].content).to eq("value1")
        end
      end

      context "with chatbot harvesting value more than one" do
        before do
          visual_component.update(component_type: "chat_bot")
          request.headers["Authorization"] = nil
          request.headers["Data-App-Id"] = data_app.id.to_s
          request.headers["Data-App-Token"] = data_app.data_app_token
        end

        it "fetches data from the model and returns success" do
          post :fetch_data, params: valid_fetch_params.merge(id: data_app.id)

          expect(response).to have_http_status(:unprocessable_content)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:errors].first).to include(
            "detail" => "Data Fetch Failed: Chat bot component requires exactly one harvest value",
            "status" => 422,
            "title" => "Error"
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

        it "fetches data from dynamic sql model and returns success" do
          post :fetch_data, params: valid_fetch_params_dynamic_sql.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)

          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data_app]).not_to be_nil
          expect(response_hash[:data_app][:results].first).to include(
            data: [{
              "id" => 1,
              "email" => "test1@mail.com",
              "first_name" => "John",
              "Last Name" => "Doe"
            }],
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
        expect(response).to have_http_status(:unprocessable_content)
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
        expect(response).to have_http_status(:unprocessable_content)
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
        expect(response).to have_http_status(:unprocessable_content)
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
  describe "POST /enterprise/api/v1/data_apps/preview" do
    let(:preview_params) do
      {
        preview: {
          model_id: ai_ml_model.id,
          payload: {
            inputs: [3]
          }
        }
      }
    end
    let(:record) do
      Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                    "first_name" => "John", "Last Name" => "Doe" },
                                                            emitted_at: DateTime.now.to_i).to_multiwoven_message
    end

    context "when the preview call is successful" do
      before do
        allow(ai_ml_connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_return([record])
      end
      it "returns a successful preview response admin role" do
        post :preview, params: preview_params
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash).to include(
          data: {
            "id" => 1,
            "email" => "test1@mail.com",
            "first_name" => "John",
            "Last Name" => "Doe"
          },
          errors: nil
        )
      end

      it "returns a successful preview response member role" do
        workspace.workspace_users.first.update(role: member_role)
        post :preview, params: preview_params
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash).to include(
          data: {
            "id" => 1,
            "email" => "test1@mail.com",
            "first_name" => "John",
            "Last Name" => "Doe"
          },
          errors: nil
        )
      end

      it "returns a successful preview response viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        post :preview, params: preview_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the preview call fails" do
      before do
        allow(ai_ml_connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_return(nil)
      end

      it "returns an error response" do
        post :preview, params: preview_params
        expect(response).to have_http_status(:ok)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors]).to eq("No data found")
      end
    end

    context "when the preview call fails" do
      before do
        allow(ai_ml_connector.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:read).and_raise(StandardError, "Simulated error")
      end

      it "returns an error response" do
        post :preview, params: preview_params
        expect(response).to have_http_status(:unprocessable_content)

        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first[:detail]).to eq(
          "Preview Failed: Simulated error"
        )
      end
    end
  end

  describe "POST /enterprise/api/v1/data_apps/:id/fetch_data_stream" do
    let!(:session) { create(:data_app_session, data_app:, session_id: "session_1") }
    let(:valid_stream_params) do
      {
        fetch_data_stream: {
          session_id: session.session_id,
          visual_component_id: visual_component.id,
          harvest_values: {
            "key1" => "value1"
          }
        }
      }
    end
    let(:record) do
      Multiwoven::Integrations::Protocol::RecordMessage.new(
        data: {
          "model": "llama3.2", "created_at": "2024-12-13T12:49:16.349172Z", "response": "hello", "done": false
        },
        emitted_at: DateTime.now.to_i
      ).to_multiwoven_message
    end
    let(:record1) do
      Multiwoven::Integrations::Protocol::RecordMessage.new(
        data: {
          "model": "llama3.2", "created_at": "2024-12-13T12:49:16.349172Z", "response": "world", "done": false
        },
        emitted_at: DateTime.now.to_i
      ).to_multiwoven_message
    end

    let(:payload) do
      "{\"messages\":[{\"role\":\"This is an ongoing conversation between a user and an AI assistant. "\
      "The assistant should provide helpful, relevant responses directly to the user's query in a "\
      "natural and conversational manner.\\n\\n" \
      "Conversation History:\\n"\
      "User: User message\\n" \
      "Assistant: Assistant message\\n\\n" \
      "User's Query:\\nvalue1\\n\\n\\n"\
      "Please respond directly to the user's query.\",\"test\":\"hai\"}]}"
    end

    let(:sync_config) { build_sync_config(visual_component.model, payload) }

    before do
      visual_component.update(component_type: "chat_bot")
    end

    context "when authenticated" do
      before do
        chat_message_user
        chat_message_assistant
        allow_any_instance_of(visual_component.model.connector.connector_client).to receive(:read)
          .with(sync_config) do |&block|
            block.call([record])
            block.call([record1])
          end
      end

      context "with valid params" do
        it "streams data from the model and returns success" do
          post :fetch_data_stream, params: valid_stream_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("text/event-stream")
          expect(response.headers["Cache-Control"]).to eq("no-cache")
          expect(response.headers["Connection"]).to eq("keep-alive")
        end
      end

      context "with data app token" do
        before do
          request.headers["Authorization"] = nil
          request.headers["Data-App-Id"] = data_app.id.to_s
          request.headers["Data-App-Token"] = data_app.data_app_token
        end

        it "fetches data from the model and returns success" do
          post :fetch_data_stream, params: valid_stream_params.merge(id: data_app.id)

          expect(response).to have_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq("text/event-stream")
          expect(response.headers["Cache-Control"]).to eq("no-cache")
          expect(response.headers["Connection"]).to eq("keep-alive")
        end
      end

      context "with an exception during the stream" do
        before do
          allow_any_instance_of(visual_component.model.connector.connector_client).to receive(:read)
            .and_raise(StandardError, "Stream error")
        end

        it "returns an error message" do
          post :fetch_data_stream, params: valid_stream_params.merge(id: data_app.id)

          expect(response).to have_http_status(:unprocessable_content)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:errors].first).to include(
            "detail" => "Error in fetch_data_stream: Stream error for visual_component_id: #{visual_component.id}",
            "status" => 422,
            "title" => "Error"
          )
        end
      end
    end

    context "session handling" do
      before do
        allow_any_instance_of(visual_component.model.connector.connector_client).to receive(:read) do |&block|
          block.call([record])
          block.call([record1])
        end
        request.headers["Authorization"] = nil
        request.headers["Data-App-Id"] = data_app.id.to_s
        request.headers["Data-App-Token"] = data_app.data_app_token
      end

      context "when a session exists" do
        it "fetches data without creating a new session" do
          initial_session_count = data_app.data_app_sessions.count
          post :fetch_data_stream, params: valid_stream_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          expect(data_app.data_app_sessions.count).to eq(initial_session_count)
        end
      end

      context "when no session exists" do
        it "creates a new session" do
          initial_session_count = data_app.data_app_sessions.count
          modified_fetch_params = valid_stream_params.deep_merge(fetch_data_stream: { session_id: "new_session_id" })
          post :fetch_data_stream, params: modified_fetch_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          expect(data_app.data_app_sessions.count).to eq(initial_session_count + 1)
        end
      end

      context "when the session is expired" do
        before do
          session.update(end_time: 1.minute.ago) # Simulate an expired session
        end
        it "returns an unauthorized error" do
          post :fetch_data_stream, params: valid_stream_params.merge(id: data_app.id)
          expect(response).to have_http_status(:unauthorized)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:errors].first[:detail])
            .to eq("Session session_1 has expired. Please start a new session.")
        end
      end
    end

    context "with invalid params" do
      let(:invalid_stream_params) do
        {
          fetch_data_stream: {
            session_id: "12324",
            visual_component_id: 100_923,
            harvest_values: {}
          }
        }
      end

      it "returns an error message for invalid params" do
        get :fetch_data_stream, params: invalid_stream_params.merge(id: data_app.id)

        expect(response).to have_http_status(:unprocessable_content)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first).to include(
          "detail" => "Error in fetch_data_stream: Visual Component not found for visual_component_id: 100923",
          "status" => 422,
          "title" => "Error"
        )
      end
    end
  end

  describe "POST /enterprise/api/v1/data_apps/:id/write_data" do
    let(:destination) { create(:connector, workspace:, connector_name: "Postgresql", connector_type: "destination") }

    let!(:catalog) do
      create(:catalog, connector: destination,
                       catalog: {
                         "request_rate_limit" => 60,
                         "request_rate_limit_unit" => "minute",
                         "request_rate_concurrency" => 2,
                         "streams" => [{ "name" => "test_stream", "batch_support" => true, "batch_size" => 10,
                                         "json_schema" => {} }]
                       })
    end

    let!(:visual_component) do
      create(:visual_component, data_app:,
                                workspace:,
                                configurable: ai_ml_model,
                                component_type: "custom")
    end

    let(:sync_config) do
      Multiwoven::Integrations::Protocol::SyncConfig.new(
        model: Model.new(
          name: data_app.name,
          query: "",
          query_type: destination.connector_query_type,
          primary_key: "id"
        ).to_protocol,
        source: destination.to_protocol,
        destination: destination.to_protocol,
        stream: catalog.stream_to_protocol(catalog.find_stream_by_name("test_stream")),
        sync_mode: Multiwoven::Integrations::Protocol::SyncMode["incremental"],
        destination_sync_mode: Multiwoven::Integrations::Protocol::DestinationSyncMode["upsert"],
        primary_key: "id"
      )
    end

    let(:connector_spec) do
      Multiwoven::Integrations::Protocol::ConnectorSpecification.new(
        connector_query_type: "raw_sql",
        stream_type: "dynamic",
        connection_specification: {
          :$schema => "http://json-schema.org/draft-07/schema#",
          :title => "Postgres",
          :type => "object",
          :stream => {}
        }
      )
    end

    let!(:session) { create(:data_app_session, data_app:, session_id: "session_1") }
    let(:write_configuration) do
      {
        "destination_id" => destination.id,
        "stream" => "test_stream",
        "primary_key" => "id"
      }
    end

    let(:valid_update_params) do
      {
        write_data: {
          session_id: session.session_id,
          write_configuration:,
          records: [{ data: { "id" => "1", "name" => "Test Record 1" } }]
        }
      }
    end

    let(:tracker) do
      Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 1,
        failed: 0,
        logs: [
          Multiwoven::Integrations::Protocol::LogMessage.new(
            name: self.class.name,
            level: "info",
            message: { request: "Sample req", response: "Sample req", level: "info" }.to_json
          )
        ]
      )
    end
    let(:multiwoven_message) { tracker.to_multiwoven_message }
    let(:client) { instance_double(destination.connector_client) }

    before do
      allow(client).to receive(:connector_spec).and_return(connector_spec)
      allow(destination.connector_client).to receive(:new).and_return(client)
      allow(client).to receive(:write).with(sync_config,
                                            [valid_update_params[:write_data][:records].first[:data].to_h],
                                            "destination_update").and_return(multiwoven_message)
    end

    context "when authenticated" do
      it "processes records and returns a success response" do
        post :write_data, params: valid_update_params.merge(id: data_app.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("data")
        response_data = JSON.parse(response.body)["data"]
        expect(response_data.size).to eq(1)
        expect(response_data.first["status"]).to eq("success")

        log = response_data.first["log"]
        expect(log).to be_a(Hash)
        expect(log).to include("request", "response", "level")
        expect(log["request"]).to eq("Sample req")
        expect(log["response"]).to eq("Sample req")
        expect(log["level"]).to eq("info")
      end
    end

    context "when the update fails" do
      before do
        allow(client).to receive(:write).and_return(
          Multiwoven::Integrations::Protocol::TrackingMessage.new(success: 0, failed: 1).to_multiwoven_message
        )
      end

      it "returns an error message" do
        post :write_data, params: valid_update_params.merge(id: data_app.id)

        expect(response).to have_http_status(:ok)
        response_data = JSON.parse(response.body)["data"]
        expect(response_data.size).to eq(1)
        expect(response_data.first["status"]).to eq("failed")
      end
    end

    context "when an exception occurs" do
      before do
        allow(client).to receive(:write).and_raise(StandardError, "Error in write operation")
      end

      it "returns a server error message" do
        post :write_data, params: valid_update_params.merge(id: data_app.id)

        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:errors].first[:error]).to eq("Error in write operation")
      end
    end

    context "session handling" do
      context "when a session exists" do
        it "fetches data without creating a new session" do
          initial_session_count = data_app.data_app_sessions.count
          post :write_data, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          expect(data_app.data_app_sessions.count).to eq(initial_session_count)
        end
      end

      context "when no session exists" do
        it "creates a new session" do
          initial_session_count = data_app.data_app_sessions.count
          modified_params = valid_update_params.deep_merge(write_data: { session_id: "new_session_id" })
          post :write_data, params: modified_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          expect(data_app.data_app_sessions.count).to eq(initial_session_count + 1)
        end
      end

      context "when the session is expired" do
        before do
          session.update(end_time: 1.minute.ago) # Simulate an expired session
        end
        it "returns an unauthorized error" do
          post :write_data, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:unauthorized)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:errors].first[:detail])
            .to eq("Session session_1 has expired. Please start a new session.")
        end
      end
    end
  end
end
