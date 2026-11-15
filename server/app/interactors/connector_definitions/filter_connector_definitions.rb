# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectorDefinitions
    include Interactor

    def call
      context.connectors = Multiwoven::Integrations::Service.connectors.with_indifferent_access

      filter_connectors_by_category if context.category.present?
      filter_connectors_by_sub_category if context.sub_category.present?
      context.connectors = context.connectors[context.type] if context.type.present?
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

    def filter_connectors_by_sub_category
      sub_categories = case context.sub_category
                       when "llm"
                         Connector::LLM_SUB_CATEGORIES
                       when "database"
                         Connector::DATABASE_SUB_CATEGORIES
                       when "web"
                         Connector::WEB_SUB_CATEGORIES
                       when "ai_ml_service"
                         Connector::AI_ML_SERVICE_SUB_CATEGORIES
                       when "vector"
                         Connector::VECTOR_SUB_CATEGORIES
                       else
                         [context.sub_category]
                       end
      context.connectors[:source] = filter_by_sub_category(context.connectors[:source], sub_categories)
      context.connectors[:destination] = filter_by_sub_category(context.connectors[:destination], sub_categories)
    end

    def filter_by_category(connectors, categories)
      connectors.select { |connector| categories.include?(connector[:category]) }
    end
<<<<<<< HEAD
=======

    def filter_by_sub_category(connectors, sub_categories)
      connectors.select { |connector| sub_categories.include?(connector[:sub_category]) }
    end

    def filter_hosted_data_stores(connectors, workspace)
      hosted_data_store_templates = ::HostedDataStores::HostedDataStoreTemplateList.call(
        workspace:
      ).data.reverse
      hosted_data_store_templates.each do |hosted_data_store_template|
        connector = connectors.find do |c|
          c[:name] == HOSTED_DATA_STORES[hosted_data_store_template[:name]]
        end
        next if connector.blank?
        next if hosted_data_store_template[:action_state] == "coming_soon"

        connector = connector.deep_dup

        connector[:name] = hosted_data_store_template[:name].gsub(" ", "")
        connector[:title] = hosted_data_store_template[:name]
        connector[:icon] = Utils::Constants::HOSTED_DATA_STORE_ICON

        if hosted_data_store_template[:linked]
          connector[:in_host] = true
          connector[:store_enabled] = hosted_data_store_template[:store_enabled]
          connector[:in_host_store_id] = hosted_data_store_template[:linked_data_store_id]
        else
          connector[:in_host] = false
          connector[:store_enabled] = false
          connector[:in_host_store_id] = nil
        end
        connectors.unshift(connector)
      end
      connectors
    end
>>>>>>> a81cf23d0 (chore(CE): connector model extraction api changes (#1609))
  end
end
