# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      # rubocop:disable Metrics/ClassLength
      class DataAppsController < EnterpriseBaseController
        include DataApps
        include AuditLogger
        skip_before_action :authenticate_user!
        before_action :authenticate_user_or_data_app!
        before_action :set_data_app, only: %i[show update destroy fetch_data]
        before_action :fetch_or_save_session, only: [:fetch_data]
        after_action :create_audit_log

        def index
          @data_apps = current_workspace.data_apps.order(updated_at: :desc)
          authorize @data_apps
          @data_apps = @data_apps.page(params[:page] || 1)
          render json: @data_apps, status: :ok
        end

        def show
          authorize @data_app
          @audit_resource = @data_app.name
          render json: @data_app, status: :ok
        end

        def create
          authorize current_workspace, policy_class: DataAppPolicy
          result = CreateDataAppOrganizer.call(
            workspace: current_workspace,
            data_app_params:,
            visual_components_params:
          )

          if result.success?
            @audit_resource = result.data_app.name
            @payload = data_app_params
            @audit_workspace = result.data_app.workspace
            render json: result.data_app, status: :created
          else
            render_error(message: "DataApp Create Failed: #{result.errors}",
                         details: result.errors, status: :unprocessable_entity)
          end
        end

        def update
          authorize @data_app
          result = UpdateDataAppOrganizer.call(
            data_app: @data_app,
            data_app_params:,
            visual_components_params:
          )

          if result.success?
            @audit_resource = @data_app.name
            @payload = data_app_params
            @audit_workspace = @data_app.workspace
            render json: result.data_app, status: :ok
          else
            render_error(message: "DataApp Update Failed: #{result.errors}",
                         details: result.errors, status: :unprocessable_entity)
          end
        end

        def destroy
          authorize @data_app
          @audit_resource = @data_app.name
          @audit_workspace = @data_app.workspace
          @data_app.destroy!
          head :no_content
        end

        def fetch_data
          authorize @data_app
          result = FetchData.call(
            data_app: @data_app,
            fetch_data_params:
          )

          if result.success?
            @audit_resource = @data_app.name
            @payload = fetch_data_params
            @audit_workspace = @data_app.workspace
            response = {
              data_app: DataAppSerializer.new(@data_app).as_json.merge(results: result.results)
            }
            render json: response, status: :ok
          else
            render_error(
              message: "Data Fetch Failed: #{result.errors}",
              details: result.errors,
              status: :unprocessable_entity
            )
          end
        end

        private

        def fetch_or_save_session
          session = @data_app.data_app_sessions.find_by(session_id: fetch_data_params[:session_id])
          if session.nil?
            @data_app.data_app_sessions.create(session_id: fetch_data_params[:session_id],
                                               data_app: @data_app, workspace: @data_app.workspace)
          elsif session.expired?
            render_error(
              message: "Session #{fetch_data_params[:session_id]} has expired. Please start a new session.",
              status: :unauthorized
            )
          end
        end

        def set_data_app
          @data_app = current_workspace.data_apps.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render_error(
            message: "DataApp not found",
            status: :not_found
          )
        end

        def create_audit_log
          audit!(resource_id: params[:id], resource: @audit_resource, payload: @payload, workspace: @audit_workspace)
        end

        def data_app_params
          params.require(:data_app).permit(:name, :description, :status, meta_data: {})
        end

        def visual_components_params
          params.require(:data_app).permit(
            visual_components: [
              :id,
              :component_type,
              :model_id,
              { properties: {} },
              { feedback_config: {} }
            ]
          )[:visual_components]
        end

        def fetch_data_params
          params.require(:fetch_data).permit(
            :session_id,
            visual_components: [
              :visual_component_id,
              { harvest_values: {} }
            ]
          )
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
