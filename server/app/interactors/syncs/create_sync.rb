# frozen_string_literal: true

module Syncs
  class CreateSync
    include Interactor

    def call
      source = context.workspace.connectors.find_by(id: context.sync_params.with_indifferent_access[:source_id])

      default_cursor_field = source.catalog&.default_cursor_field(context.sync_params[:stream_name])
      context.sync_params[:cursor_field] = default_cursor_field if default_cursor_field.present?
      sync = context
             .workspace.syncs
             .create(context.sync_params)
      if sync.persisted?
        context.sync = sync
      else
        context.fail!(sync:)
      end
    end
  end
end
