# frozen_string_literal: true

module Enterprise
  module Api
    module V1
      class EmbedOriginsController < EnterpriseBaseController
        include AuditLogger

        before_action :authenticate_user!, except: :lookup
        skip_after_action :verify_authorized, only: :lookup

        def lookup
          workspace_id = EmbedOrigins::Registry.workspace_id_for_data_app(params[:data_app_id])
          return render(json: { origins: [] }, status: :ok) unless workspace_id

          origins = EmbedOrigins::Registry.allowlist_for(workspace_id).to_a
          render json: {
            origins:,
            meta: EmbedOrigins::Registry.propagation_meta
          }, status: :ok
        end

        def index
          authorize current_workspace, policy_class: UserEmbedOriginPolicy
          render json: scoped_records.includes(:created_by_user).order(:origin).as_json(
            only: %i[id origin workspace_id organization_id created_at],
            include: { created_by_user: { only: %i[id email] } }
          )
        end

        def create
          authorize current_workspace, policy_class: UserEmbedOriginPolicy
          record = UserEmbedOrigin.new(
            origin: params[:origin],
            created_by_user: current_user,
            organization_id: current_organization.id,
            **scope_attributes
          )

          if record.save
            audit!(
              action: "embed_origin.add",
              resource_type: "UserEmbedOrigin",
              resource_id: record.id,
              payload: { origin: record.origin, scope: params[:scope] }
            )
            render json: { data: record, meta: EmbedOrigins::Registry.propagation_meta }, status: :created
          else
            render_error(
              message: "Invalid origin",
              status: :unprocessable_content,
              details: format_errors(record)
            )
          end
        rescue ActiveRecord::RecordNotUnique
          render_error(message: "Origin is already allowed", status: :unprocessable_content)
        end

        def update
          authorize current_workspace, policy_class: UserEmbedOriginPolicy
          record = current_organization.embed_origins.find(params[:id])
          previous_origin = record.origin

          if record.update(origin: params[:origin])
            audit!(
              action: "embed_origin.update",
              resource_type: "UserEmbedOrigin",
              resource_id: record.id,
              payload: { previous_origin:, origin: record.origin }
            )
            render json: { data: record, meta: EmbedOrigins::Registry.propagation_meta }, status: :ok
          else
            render_error(
              message: "Invalid origin",
              status: :unprocessable_content,
              details: format_errors(record)
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_error(message: "Embed origin not found", status: :not_found)
        rescue ActiveRecord::RecordNotUnique
          render_error(message: "Origin is already allowed", status: :unprocessable_content)
        end

        def destroy
          authorize current_workspace, policy_class: UserEmbedOriginPolicy
          record = current_organization.embed_origins.find(params[:id])
          record.destroy!
          audit!(
            action: "embed_origin.remove",
            resource_type: "UserEmbedOrigin",
            resource_id: record.id,
            payload: {
              origin: record.origin,
              scope: record.workspace_id.nil? ? "organization" : "workspace"
            }
          )
          render json: { meta: EmbedOrigins::Registry.propagation_meta }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_error(message: "Embed origin not found", status: :not_found)
        end

        private

        def scoped_records
          base = UserEmbedOrigin.where(organization_id: current_organization.id)
          case params[:scope]
          when "organization" then base.where(workspace_id: nil)
          when "workspace"    then base.where(workspace_id: current_workspace.id)
          else                     base
          end
        end

        def scope_attributes
          params[:scope] == "organization" ? { workspace_id: nil } : { workspace_id: current_workspace.id }
        end
      end
    end
  end
end
