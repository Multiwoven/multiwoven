# frozen_string_literal: true

module ConnectorDefinitions
  class FilterConnectorDefinitions
    include Interactor

    HOSTED_DATA_STORES = {
      "AI Squared Vector Store" => "Postgresql",
      "AI Squared Database" => "Postgresql"
    }.freeze

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
      context.connectors[:source] = filter_hosted_data_stores(context.connectors[:source], context.workspace)
      context.connectors[:destination] = filter_by_category(context.connectors[:destination], categories)
      context.connectors[:destination] = filter_hosted_data_stores(context.connectors[:destination], context.workspace)
    end

    def filter_by_category(connectors, categories)
      connectors.select { |connector| categories.include?(connector[:category]) }
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
  end
end
