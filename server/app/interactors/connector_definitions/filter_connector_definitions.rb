# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectorDefinitions
    include Interactor

<<<<<<< HEAD
=======
    HOSTED_DATA_STORES = {
      "AI Squared Vector Store" => "Postgresql",
      "AI Squared Database" => "Postgresql"
    }.freeze

    SUB_CATEGORY_MAP = {
      "llm" => Connector::LLM_SUB_CATEGORIES,
      "database" => Connector::DATABASE_SUB_CATEGORIES,
      "web" => Connector::WEB_SUB_CATEGORIES,
      "ai_ml_service" => Connector::AI_ML_SERVICE_SUB_CATEGORIES,
      "vector" => Connector::VECTOR_SUB_CATEGORIES
    }.freeze

>>>>>>> f6d71341a (fix(CE): added an extra filter in connectors api for excluding on basis of sub category (#1893))
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
<<<<<<< HEAD
=======
      context.connectors[:destination] = filter_hosted_data_stores(context.connectors[:destination], context.workspace)
    end

    def filter_connectors_by_sub_category
      sub_categories = SUB_CATEGORY_MAP.fetch(context.sub_category, [context.sub_category])
      context.connectors[:source] = filter_by_sub_category(context.connectors[:source], sub_categories)
      context.connectors[:destination] = filter_by_sub_category(context.connectors[:destination], sub_categories)
>>>>>>> f6d71341a (fix(CE): added an extra filter in connectors api for excluding on basis of sub category (#1893))
    end

    def filter_by_category(connectors, categories)
      connectors.select { |connector| categories.include?(connector[:category]) }
    end
  end
end
