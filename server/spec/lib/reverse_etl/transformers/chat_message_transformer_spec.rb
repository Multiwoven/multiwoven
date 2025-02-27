# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::ChatMessageTransformer, type: :service do
  let(:chat_history) do
    [
      { role: "user", content: "Hello, how can I reset my password?" },
      { role: "assistant", content: "To reset your password, please go to the settings page." }
    ]
  end
  let(:latest_user_query) { "Where is the settings page?" }
  let(:transformer) { described_class.new(chat_history, latest_user_query) }

  describe "#transform" do
    it "correctly formats the chat history and user query into the prompt" do
      expected_output = "The following is a conversation between a user and an AI assistant.\n" \
                        "User: Hello, how can I reset my password?\n" \
                        "Assistant: To reset your password, please go to the settings page.\n" \
                        "User Query:\nWhere is the settings page?"

      expect(transformer.transform).to eq(expected_output)
    end

    context "when there is an error during transformation" do
      before do
        allow(transformer).to receive(:format_history).and_raise(StandardError, "Something went wrong")
      end

      it "logs the error and returns nil" do
        expect(Rails.logger).to receive(:error).with({
          error_message: "Something went wrong",
          chat_history:,
          latest_user_query:,
          stack_trace: ["lib/reverse_etl/transformers/chat_message_transformer.rb:16:in `transform'"]
        }.to_s)
        expect(transformer.transform).to be_nil
      end
    end
  end

  describe "#format_history" do
    it "correctly formats the chat history" do
      expected_history = "User: Hello, how can I reset my password?\n" \
                         "Assistant: To reset your password, please go to the settings page."

      expect(transformer.send(:format_history)).to eq(expected_history)
    end
  end
end
