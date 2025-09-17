# frozen_string_literal: true

module DataApps
  class FetchVisualComponentData
    include Interactor
    include Concerns::DataApps::FetchDataHelpers
    include Concerns::DataApps::ChatbotHelpers

    def call
      visual_component = find_visual_component
      model = visual_component.model
      harvest_values = context.param[:harvest_values] || {}
      original_harvest_values = harvest_values.dup

      # pre-process user query for chatbot
      if visual_component.chat_bot? && visual_component.model.connector.connector_name != "HttpModel"
        modify_user_prompt_query(visual_component, context.session, harvest_values)
      end

      payload = build_payload(model, harvest_values)
      sync_config = build_sync_config(model, payload)

      client = model.connector.connector_client.new
      result = handle_multiwoven_response(client.read(sync_config), model)

      if visual_component.chat_bot?
        # post-process chatbot: save query and response to chat history
        insert_to_chat_history(visual_component, context.session, original_harvest_values,
                               fetch_chat_bot_response(result, visual_component))
      end

      context.result = if result
                         {
                           visual_component_id: visual_component.id,
                           data: result,
                           errors: nil
                         }
                       else
                         {
                           visual_component_id: visual_component.id,
                           data: nil,
                           errors: "No data found"
                         }
                       end
    rescue StandardError => e
      context.result = {
        visual_component_id: context.param[:visual_component_id],
        data: nil,
        errors: e.message
      }
    end

    private

    def find_visual_component
      context.data_app.visual_components.find_by(id: context.param[:visual_component_id]) ||
        raise(StandardError, "Visual Component not found")
    end

    def build_payload(model, harvest_values)
      if model.ai_ml?
        catalog = model.connector.catalog.catalog
        input_config = catalog.dig("streams", 0, "json_schema", "input")
        Utils::PayloadGenerator::AiMl.generate_payload(input_config, harvest_values).to_json
      elsif model.dynamic_sql?
        Utils::PayloadGenerator::DynamicSql.generate_query(model, harvest_values)
      end
    end
  end
end
