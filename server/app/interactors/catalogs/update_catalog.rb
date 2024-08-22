# frozen_string_literal: true

module Catalogs
  class UpdateCatalog < CreateCatalog
    def call
      validate_catalog_params!
      unless context.catalog.update(
        catalog: catalog_params, catalog_hash: generate_catalog_hash,
        connector_id: context.connector.id, workspace_id: context.connector.workspace_id
      )
        context.fail!(model: context.model)
      end
    end
  end
end
