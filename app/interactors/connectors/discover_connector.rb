# frozen_string_literal: true

module Connectors
  class DiscoverConnector
    include Interactor

    def call
      context.catalog = context.connector.catalog
      return if context.catalog.present?

      catalog = context.connector.build_catalog(
        workspace_id: context.connector.workspace_id
      )

      catalog.catalog = streams(context.connector)
      catalog.catalog_hash = Digest::SHA1.hexdigest(catalog.catalog.to_s)
      catalog.save

      if catalog.persisted?
        context.catalog = catalog
      else
        context.fail!(errors: catalog.errors)
      end
    end

    def connector_client(connector)
      @connector_client ||= Multiwoven::Integrations::Service.connector_class(
        connector.connector_type.camelize,
        connector.connector_name.camelize
      ).new
    end

    def streams(connector)
      @streams ||= connector_client(connector)
                   .discover(connector.configuration).catalog.to_h
    end
  end
end
