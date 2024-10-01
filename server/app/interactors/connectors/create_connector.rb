# frozen_string_literal: true

module Connectors
  class CreateConnector
    include Interactor

    def call
      if connector_exists?
        context.fail!(error: "A connector with the same name already exists.")
        return
      end

      connector = context.workspace
                         .connectors
                         .create(context.connector_params)

      if connector.persisted?
        context.connector = connector
      else
        context.fail!(connector:)
      end
    end

    def connector_exists?
      context.workspace.connectors.exists?(
        name: context.connector_params["name"],
        connector_type: context.connector_params["connector_type"]
      )
    end
  end
end
