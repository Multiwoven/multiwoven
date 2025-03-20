# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectorDefinitions
    include Interactor

    def call
      context.connectors = Multiwoven::Integrations::Service.connectors.with_indifferent_access

      filter_connectors_by_category if context.category
      context.connectors = context.connectors[context.type] if context.type
    end

    private

    def filter_connectors_by_category
      categories = case context.category
                   when "data"
                     Connector::DATA_CATEGORIES
                   when "ai_ml"
                     Connector::AI_ML_CATEGORIES
                   else
                     [context.category]
                   end
      context.connectors[:source] = filter_by_category(context.connectors[:source], categories)
      context.connectors[:destination] = filter_by_category(context.connectors[:destination], categories)
    end

    def filter_by_category(connectors, categories)
      connectors.select { |connector| categories.include?(connector[:category]) }
    end
  end
end
