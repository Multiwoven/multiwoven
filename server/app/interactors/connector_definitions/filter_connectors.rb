# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectors
    include Interactor

    # TODO: Move this to integration so that whenever a new category is introduced,
    # integrations will be the single source of truth for categories

    DATA_CATEGORIES = [
      "Data Warehouse",
      "Retail",
      "Data Lake",
      "Database",
      "Marketing Automation",
      "CRM",
      "Ad-Tech",
      "Team Collaboration",
      "Productivity Tools",
      "Payments",
      "File Storage",
      "HTTP",
      "Customer Support"
    ].freeze

    AI_ML_CATEGORIES = [
      "AI Model"
    ].freeze

    def call
      context.connectors = Multiwoven::Integrations::Service.connectors.with_indifferent_access

      filter_connectors_by_category if context.category
      context.connectors = context.connectors[context.type] if context.type
    end

    private

    def filter_connectors_by_category
      categories = case context.category
                   when "data"
                     DATA_CATEGORIES
                   when "ai_ml"
                     AI_ML_CATEGORIES
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
