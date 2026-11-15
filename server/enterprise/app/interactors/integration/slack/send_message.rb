# frozen_string_literal: true

module Integration
  module Slack
    # rubocop:disable Metrics/ClassLength
    class SendMessage
      include Interactor
      include Concerns::ChatHistoryHandler

      def call
        initialize_context_variables
        validate_request!
        fetch_or_save_thread_id

        event = context.payload["event"]
        return process_bot_message if bot_message?(event)

        extract_from_event(event)
        handle_user_message
        context.result = { message: "Event processed" }
      rescue StandardError => e
        context.fail!(errors: e.message)
      end

      private

      # Initialization
      def initialize_context_variables
        @client = context.client
        @workflow = context.workflow
        @data_app = context.data_app
        @workflow_integration = context.workflow_integration
        @payload = context.payload
      end

      # Request validation
      def validate_request!
        return if valid_slack_request?(context.request, @workflow_integration)

        raise "Invalid Slack request signature"
      end

      def valid_slack_request?(request, workflow_integration)
        timestamp = request.headers["X-Slack-Request-Timestamp"]
        return false unless timestamp_valid?(timestamp)

        slack_signature = request.headers["X-Slack-Signature"]
        signing_secret = workflow_integration.connection_configuration["signing_signature"]
        expected_signature = calculate_signature(timestamp, request.raw_post, signing_secret)

        Rack::Utils.secure_compare(expected_signature, slack_signature)
      end

      def timestamp_valid?(timestamp)
        return false if timestamp.blank?

        (Time.zone.now.to_i - timestamp.to_i).abs <= 300 # 5 minutes
      end

      def calculate_signature(timestamp, raw_post, signing_secret)
        sig_basestring = "v0:#{timestamp}:#{raw_post}"
        "v0=#{OpenSSL::HMAC.hexdigest('SHA256', signing_secret, sig_basestring)}"
      end

      # Event handling
      def bot_message?(event)
        event["subtype"] == "bot_message" || event.key?("bot_id")
      end

      def process_bot_message
        context.result = { message: "Bot message ignored" }
      end

      def extract_from_event(event)
        @user_id = event["user"]
        @reply_channel = event["channel"]
        @text = event["text"]
        @ts = event["ts"]
      end

      def extract_text
        @bot_id ||= @client.auth_test["user_id"]
        @text.gsub(/<@#{@bot_id}>/, "").strip
      end

      # Session management
      def fetch_or_save_thread_id
        thread_id = extract_thread_id
        @session = find_or_create_session(thread_id)
        validate_session_expiration
      end

      def extract_thread_id
        @payload.dig("event", "thread_ts") || @payload.dig("event", "ts")
      end

      def find_or_create_session(thread_id)
        @data_app.data_app_sessions.find_or_create_by!(session_id: thread_id.to_s) do |session|
          session.data_app = @data_app
          session.workspace = @data_app.workspace
        end
      end

      def validate_session_expiration
        return unless @session.expired?

        raise "Session #{@session.session_id} has expired. Please start a new session."
      end

      # Message handling
      def handle_user_message
        text_without_mention = extract_text
        add_reaction
        send_loading_message

        workflow_result = execute_workflow(text_without_mention)

        if workflow_result.success?
          handle_successful_workflow(workflow_result, text_without_mention)
        else
          handle_failed_workflow(workflow_result)
        end
      end

      def execute_workflow(text)
        inputs = build_workflow_inputs(text)
        ::Agents::Workflows::RunWorkflow.call(workflow: @workflow, inputs:)
      end

      def build_workflow_inputs(text)
        inputs = { "text" => text }
        inputs["session_id"] = @session.session_id if @session.present?
        inputs
      end

      def handle_successful_workflow(workflow_result, text)
        output = extract_workflow_output(workflow_result)
        send_response_to_slack(output)
        persist_chat_history_async(text, output)
      end

      def handle_failed_workflow(workflow_result)
        error_message = format_workflow_error(workflow_result.message)
        Rails.logger.error("Workflow execution failed: #{error_message}")
        send_error_response(error_message)
        raise error_message
      end

      def extract_workflow_output(workflow_result)
        workflow_result.workflow_result.dig(:output, :data, "message") || "No response generated"
      end

      def format_workflow_error(message)
        if message&.include?("workflow run id")
          "Workflow execution failed: #{message}"
        else
          "workflow_run_id not found in error message: Workflow execution failed"
        end
      end

      def send_response_to_slack(output)
        if @workflow_integration.metadata["feedback_title"].present?
          send_feedback_message(output)
        else
          send_workflow_response(output)
        end
      end

      # Slack API interactions
      def add_reaction
        @client.reactions_add(
          name: "ack",
          channel: @reply_channel,
          timestamp: @ts
        )
      rescue StandardError
        @client.reactions_add(
          name: "white_check_mark",
          channel: @reply_channel,
          timestamp: @ts
        )
      end

      def send_loading_message
        loading_message = @workflow_integration.metadata["loading_message"]
        return if loading_message.blank?

        send_slack_message(text: "<@#{@user_id}> #{loading_message}")
      end

      def send_workflow_response(output)
        send_slack_message(text: "<@#{@user_id}> #{output}")
      end

      def send_feedback_message(output)
        blocks = build_feedback_blocks(output)
        send_slack_message(text: "<@#{@user_id}> #{output}", blocks:)
      end

      def send_error_response(error_message)
        send_slack_message(text: "<@#{@user_id}> #{error_message}")
      end

      def send_slack_message(text:, blocks: nil)
        @client.chat_postMessage(
          channel: @reply_channel,
          thread_ts: @ts,
          text:,
          **(blocks ? { blocks: } : {})
        )
      rescue StandardError => e
        Rails.logger.error("Slack chat_postMessage failed: #{e.class} - #{e.message}")
        context.fail!(errors: "Slack chat_postMessage failed: #{e.class} - #{e.message}")
        raise
      end

      # Feedback blocks building
      def build_feedback_blocks(output)
        [
          message_section_block(output),
          { type: "divider" },
          feedback_title_block,
          feedback_instructions_block,
          feedback_actions_block,
          followup_info_block
        ]
      end

      def message_section_block(output)
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "<@#{@user_id}> #{output}"
          }
        }
      end

      def feedback_title_block
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: @workflow_integration.metadata["feedback_title"]
          }
        }
      end

      def feedback_instructions_block
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: "Please let me know how the response was by reacting below"
            }
          ]
        }
      end

      def feedback_actions_block
        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: { type: "plain_text", text: "👍" },
              value: "thumbs_up",
              action_id: "feedback_thumbsup"
            },
            {
              type: "button",
              text: { type: "plain_text", text: "👎" },
              value: "thumbs_down",
              action_id: "feedback_thumbsdown"
            }
          ]
        }
      end

      def followup_info_block
        {
          type: "context",
          elements: [
            {
              type: "mrkdwn",
              text: ":information_source: Mention <@#{@bot_id}> in the thread to ask a follow-up questions."
            }
          ]
        }
      end

      # Chat history
      def persist_chat_history_async(text, output)
        return unless should_persist_chat_history?

        visual_component = find_visual_component
        return unless visual_component

        Thread.new do
          persist_chat_history_in_background(text, output, visual_component)
        end
      end

      def should_persist_chat_history?
        @data_app.present? && @session.present?
      end

      def find_visual_component
        @data_app.visual_components.first
      end

      def persist_chat_history_in_background(text, output, visual_component)
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_handler
                            .retrieve_connection_pool("ActiveRecord::Base")
                            .with_connection do
            @visual_component = visual_component
            save_chat_history!(text, output)
          end
        end
      rescue StandardError => e
        Rails.logger.error("Chat history insertion failed: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
