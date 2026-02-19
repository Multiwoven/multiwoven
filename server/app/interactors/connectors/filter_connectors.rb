# frozen_string_literal: true

module Connectors
  class FilterConnectors
    include Interactor

    def call
      connectors = context.workspace.connectors

      connectors = filter_by_type(connectors)
      connectors = filter_by_category(connectors)
      connectors = filter_by_sub_category(connectors)
      connectors = filter_by_provider(connectors)
      connectors = paginate(connectors)

      context.connectors = connectors
    end

    private

    def filter_by_type(connectors)
      return connectors if context.type.blank?

      connectors.send(context.type.downcase)
    end

    def filter_by_category(connectors)
      return connectors if context.category.blank?

      connectors.send(context.category.downcase)
    end

    def filter_by_sub_category(connectors)
      return connectors if context.sub_category.blank?

      connectors.send(context.sub_category.downcase)
    end

    def filter_by_provider(connectors)
      return connectors if context.provider.blank?

      connectors.where(connector_name: context.provider)
    end

    def paginate(connectors)
      page = context.page || 1
      per_page = context.per_page

      connectors.page(page).per(per_page)
    end
  end
end
