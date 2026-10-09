# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChatHistoryService, type: :service do
  let(:workspace) { create(:workspace) }
  let(:data_app) { create(:data_app, workspace:) }
  let(:visual_component) { create(:visual_component, data_app:, workspace:) }
  let(:data_app_session) { create(:data_app_session, data_app:, workspace:, title: nil) }
  let(:chat_message_user) do
    create(:chat_message, session: data_app_session, role: "user", content: "User message", workspace:,
                          visual_component:)
  end
  let(:chat_message_assistant) do
    create(:chat_message, session: data_app_session, role: "assistant", content: "Assistant message",
                          workspace:, visual_component:)
  end

  subject { described_class.new(data_app_session, visual_component) }

  describe "#chat_history" do
    before do
      chat_message_user
      chat_message_assistant
    end

    it "returns chat messages in the correct order" do
      result = subject.send(:chat_history)
      expect(result).to eq(
        [
          { role: "user", content: "User message" },
          { role: "assistant", content: "Assistant message" }
        ]
      )
    end

    it "limits the number of chat messages" do
      expect(subject.send(:chat_history, 1).size).to eq(1)
    end
  end

  describe "#create_chat_history_query" do
    let(:user_query) { "What is AI?" }

    context "when there is chat history" do
      before do
        chat_message_user
        chat_message_assistant
      end

      it "calls the transformer with history and current user query" do
        expected_output = "This is an ongoing conversation between a user and an AI assistant. "\
        "The assistant should provide helpful, relevant responses directly to the user's query in a "\
        "natural and conversational manner.\n\n" \
        "Conversation History:\n"\
        "User: User message\n" \
        "Assistant: Assistant message\n\n" \
        "User's Query:\nWhat is AI?\n\n\n"\
        "Please respond directly to the user's query."

        result = subject.create_chat_history_query(user_query)
        expect(result).to eq(expected_output)
      end
    end

    context "when there is no chat history" do
      it "returns the current user query unchanged" do
        result = subject.create_chat_history_query(user_query)
        expect(result).to eq(user_query)
      end
    end
  end

  describe "#insert_to_chat_history" do
    let(:user_query) { "What is AI?" }
    let(:assistant_response) { "AI is Artificial Intelligence." }

    it "creates two chat messages for user and assistant" do
      expect do
        subject.insert_to_chat_history(user_query, assistant_response)
      end.to change(ChatMessage, :count).by(2)

      expect(ChatMessage.last.role).to eq("assistant")
      expect(ChatMessage.last.content).to eq(assistant_response)
      expect(ChatMessage.first.role).to eq("user")
      expect(ChatMessage.first.content).to eq(user_query)
      expect(DataAppSession.last.title).to eq(user_query)
    end

    context "when query or response is blank" do
      it "does not create any chat messages" do
        expect do
          subject.insert_to_chat_history("", assistant_response)
        end.not_to change(ChatMessage, :count)

        expect do
          subject.insert_to_chat_history(user_query, nil)
        end.not_to change(ChatMessage, :count)
      end
    end
  end
end
