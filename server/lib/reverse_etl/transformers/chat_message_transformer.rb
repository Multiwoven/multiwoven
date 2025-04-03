# frozen_string_literal: true

module ReverseEtl
  module Transformers
    class ChatMessageTransformer < Base
      PROMPT_USER_TEMPLATE = "The following is a conversation between a user and an AI assistant."\
       "\n%s\nUser Query:\n%s"

      def initialize(chat_history, latest_user_query)
        super()
        @chat_history = chat_history
        @latest_user_query = latest_user_query
      end

      def transform
        format(PROMPT_USER_TEMPLATE, format_history, @latest_user_query)
      rescue StandardError => e
        Rails.logger.error({
          error_message: e.message,
          chat_history: @chat_history,
          latest_user_query: @latest_user_query,
          stack_trace: Rails.backtrace_cleaner.clean(e.backtrace)
        }.to_s)
        nil
      end

      private

      def format_history
        @chat_history.map do |message|
          "#{message[:role].capitalize}: #{message[:content]}"
        end.join("\n")
      end
    end
  end
end
