# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::DataAppsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
  let!(:ai_ml_connector) { create(:connector, workspace:, connector_category: "AI Model") }
  let!(:ai_ml_model) do
    create(:model, query_type: :ai_ml, connector: ai_ml_connector, configuration: { key: "value" }, workspace:)
  end
  let(:visual_component) { create(:visual_component, data_app:, workspace:, model: ai_ml_model) }

  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    user.update!(confirmed_at: Time.current)
    request.headers.merge!(auth_headers(user, workspace.id))
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
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")
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
        visual_components = response_hash.dig(:data, 0, :attributes, :visual_components)
        expect(visual_components.dig(0, :created_at)).not_to be_nil
        expect(visual_components.dig(0, :updated_at)).not_to be_nil
        expect(visual_components.dig(0, :model, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :model, :connector, :icon))
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
        expect(response_hash[:data].size).to eq(4)
        expect(response_hash.dig(:data, 0, :type)).to eq("data_apps")
        expect(response_hash.dig(:links, :first))
          .to include("/enterprise/api/v1/data_apps?page=1&per_page=10")
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
        visual_components = response_hash.dig(:data, :attributes, :visual_components)
        expect(visual_components.dig(0, :component_type)).to eq(data_app.visual_components.first.component_type)
        expect(visual_components.dig(0, :model, :name)).to eq(data_app.visual_components.first.model.name)
        expect(visual_components.dig(0, :model, :connector, :icon))
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
        visual_components = response_hash.dig(:data, :attributes, :visual_components)
        expect(visual_components.dig(0, :component_type)).to eq(data_app.visual_components.first.component_type)
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
          expect(response_hash[:message]).to eq("DataApp Created Successfully")
        end

        it "creates a new data app and returns success - member role" do
          workspace.workspace_users.first.update(role: member_role)
          post :create, params: valid_params
          expect(response).to have_http_status(:created)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:message]).to eq("DataApp Created Successfully")
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
          expect(response_hash[:message]).to eq("DataApp Updated Successfully")
          expect(data_app.reload.name).to eq("Updated Sales Dashboard")
          expect(visual_component.reload.component_type).to eq("bar")
        end

        it "updates the data app and returns success - member role" do
          workspace.workspace_users.first.update(role: member_role)
          put :update, params: valid_update_params.merge(id: data_app.id)
          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:message]).to eq("DataApp Updated Successfully")
          expect(data_app.reload.name).to eq("Updated Sales Dashboard")
          expect(visual_component.reload.component_type).to eq("bar")
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
        expect(response_hash[:message]).to eq("DataApp Updated Successfully")
        expect(data_app.reload.visual_components.count).to eq(2) # Ensure 2 components after update
        expect(data_app.visual_components.last.component_type).to eq("doughnut")
        expect(data_app.visual_components.last.name).to be_nil
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
        expect(response_hash[:message]).to eq("DataApp Updated Successfully")
        expect(data_app.reload.visual_components.count).to eq(1) # Ensure only 1 component after update
        expect(data_app.visual_components).to include(existing_visual_component)
        expect(data_app.visual_components).not_to include(extra_component)
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
end
