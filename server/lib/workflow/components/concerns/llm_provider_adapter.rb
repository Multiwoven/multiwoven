# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Workflow
  module Components
    module Concerns
      # Handles provider-specific payload construction and response extraction for LLM components
      # Supports: OpenAI, Anthropic, AWS Bedrock, Generic OpenAI
      module LlmProviderAdapter
        extend ActiveSupport::Concern

        # Build provider-specific payload for LLM API request
        def build_llm_payload(connector, messages, system_instruction)
          request_format = connector.configuration["request_format"]

          if request_format.blank?
            raise "Missing request_format in connector configuration for #{connector.connector_name}"
          end

          begin
            request = JSON.parse(request_format)
          rescue JSON::ParserError => e
            raise "Invalid JSON in request_format for #{connector.connector_name}: #{e.message}"
          end

          model_name = request["model"]

          case connector.connector_name
          when "Anthropic"
            build_anthropic_payload(messages, system_instruction, model_name, request, connector)
          when "AwsBedrockModel"
            build_bedrock_payload(messages, system_instruction, model_name, request, connector)
          when "GenericOpenAI"
            build_generic_openai_payload(messages, system_instruction, model_name, request)
          when "Aisquared"
            build_aisquared_payload(messages, request)
          else
            # Default to OpenAI format
            build_openai_payload(messages, system_instruction, model_name, request)
          end
        end

        # Extract response content from provider-specific response format
        def extract_llm_response(response, connector)
          case connector.connector_name
          when "Anthropic"
            extract_anthropic_response(response)
          when "AwsBedrockModel"
            extract_bedrock_response(response)
          when "GenericOpenAI"
            extract_openai_response(response) # Same format as OpenAI
          when "Aisquared"
            extract_aisquared_response(response)
          else
            # Default to OpenAI format
            extract_openai_response(response)
          end
        end

        private

        def build_anthropic_payload(messages, system_instruction, model_name, request, connector)
          system_messages = messages.select { |m| m["role"] == "system" }
          filtered_messages = messages.reject { |m| m["role"] == "system" }
          combined_system = combine_system_messages(system_messages, system_instruction)
          max_tokens = extract_max_tokens(request, connector)

          {
            "model" => model_name,
            "system" => combined_system,
            "messages" => filtered_messages,
            "max_tokens" => max_tokens
          }
        end

        def extract_anthropic_response(response)
          message = response.is_a?(Array) ? response.first : response
          return nil unless valid_response_message?(message)

          data = message.record.data
          extract_text_from_content_blocks(data["content"])
        end

        def build_bedrock_payload(messages, system_instruction, model_name, request, connector)
          # AWS Bedrock supports different models with different formats
          # For Anthropic models on Bedrock, use Anthropic format
          if model_name&.include?("anthropic")
            system_messages = messages.select { |m| m["role"] == "system" }
            filtered_messages = messages.reject { |m| m["role"] == "system" }
            combined_system = combine_system_messages(system_messages, system_instruction)
            max_tokens = extract_max_tokens(request, connector)

            {
              "model" => model_name,
              "system" => combined_system,
              "messages" => filtered_messages,
              "max_tokens" => max_tokens
            }
          else
            # For other Bedrock models (Titan, etc.), use standard format
            unless messages.any? { |m| m["role"] == "system" }
              messages.unshift({ "role" => "system", "content" => system_instruction })
            end

            {
              "model" => model_name,
              "messages" => messages,
              "max_tokens" => extract_max_tokens(request, connector)
            }
          end
        end

        def extract_bedrock_response(response)
          message = response.is_a?(Array) ? response.first : response
          return nil unless message.respond_to?(:record) && message.record.present?

          data = message.record.data
          # Bedrock uses OpenAI-compatible response format in the integration
          data.dig("choices", 0, "message", "content")
        end

        def build_openai_payload(messages, system_instruction, model_name, request)
          # Add system message if not present
          unless messages.any? { |m| m["role"] == "system" }
            messages.unshift(
              {
                "role" => "system",
                "content" => system_instruction
              }
            )
          end

          payload = {
            "model" => model_name,
            "messages" => messages
          }

          # Add optional parameters if present in request_format
          payload["temperature"] = request["temperature"] if request["temperature"]
          payload["max_tokens"] = request["max_tokens"] if request["max_tokens"]
          payload["top_p"] = request["top_p"] if request["top_p"]

          payload
        end

        def extract_openai_response(response)
          message = response.is_a?(Array) ? response.first : response
          return nil unless message.respond_to?(:record) && message.record.present?

          data = message.record.data
          data.dig("choices", 0, "message", "content")
        end

        def build_generic_openai_payload(messages, system_instruction, model_name, request)
          # Generic OpenAI uses the same format as OpenAI
          build_openai_payload(messages, system_instruction, model_name, request)
        end

        def build_aisquared_payload(messages, request)
          payload = {
            "messages" => messages
          }

          # Add optional parameters if present in request_format
          payload["temperature"] = request["temperature"] if request["temperature"]
          payload["max_tokens"] = request["max_tokens"] if request["max_tokens"]

          payload
        end

        def extract_aisquared_response(response)
          message = response.is_a?(Array) ? response.first : response
          return nil unless message.respond_to?(:record) && message.record.present?

          data = message.record.data
          data.dig("choices", 0, "message", "content")
        end

        # Helper methods for building payloads
        def combine_system_messages(system_messages, system_instruction)
          combined = system_messages.map { |m| m["content"] }.join("\n\n")
          combined = [combined, system_instruction].reject(&:blank?).join("\n\n")
          combined.presence || system_instruction
        end

        def extract_max_tokens(request, connector)
          request["max_tokens"] || connector.configuration["max_tokens"] || 4096
        end

        def check_llm_response_for_errors(message, workflow_run_id)
          return unless message.respond_to?(:log) && message.log.present?

          log_message = message.log
          return unless log_message.is_a?(Multiwoven::Integrations::Protocol::LogMessage) &&
                        log_message.level == "error"

          error_msg = log_message.message
          Rails.logger.error(
            "[workflow_run_id: #{workflow_run_id}] LlmModelComponent: " \
            "LLM API request failed - Error LogMessage: #{error_msg.presence || 'Unknown error'}"
          )
          raise "LLM API request failed: #{error_msg.presence || 'Unknown error'}"
        end

        def valid_response_message?(message)
          message.respond_to?(:record) && message.record.present?
        end

        def extract_text_from_content_blocks(content_blocks)
          return nil unless content_blocks.is_a?(Array) && content_blocks.any?

          text_block = content_blocks.find { |block| block["type"] == "text" }
          text_block&.dig("text")
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
