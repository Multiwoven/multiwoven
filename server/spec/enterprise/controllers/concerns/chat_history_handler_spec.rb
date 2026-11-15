# frozen_string_literal: true

require "rails_helper"

RSpec.describe Concerns::ChatHistoryHandler, type: :module do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Concerns::ChatHistoryHandler

      attr_accessor :session, :visual_component

      def initialize(session, visual_component)
        @session = session
        @visual_component = visual_component
      end
    end
  end

  let(:workspace) { create(:workspace) }
  let(:data_app) { create(:data_app, workspace:) }
  let(:visual_component) { create(:visual_component, data_app:, workspace:) }
  let(:data_app_session) { create(:data_app_session, data_app:, workspace:, title: nil) }
  let(:test_instance) { test_class.new(data_app_session, visual_component) }

  describe "#chat_history_service" do
    it "creates a new ChatHistoryService instance with session and visual_component" do
      expect(ChatHistoryService).to receive(:new).with(data_app_session, visual_component).and_call_original

      service = test_instance.chat_history_service

      expect(service).to be_a(ChatHistoryService)
    end

    it "memoizes the ChatHistoryService instance" do
      first_service = test_instance.chat_history_service
      second_service = test_instance.chat_history_service

      expect(first_service).to be(second_service)
    end

    it "creates service with correct parameters" do
      service = test_instance.chat_history_service

      # Access private instance variables to verify they're set correctly
      expect(service.instance_variable_get(:@chat_session)).to eq(data_app_session)
      expect(service.instance_variable_get(:@visual_component)).to eq(visual_component)
    end
  end

  describe "#save_chat_history!" do
    let(:query) { "What is the weather today?" }
    let(:response) { "The weather is sunny and 75°F." }
    let(:chat_history_service) { instance_double(ChatHistoryService) }

    before do
      allow(test_instance).to receive(:chat_history_service).and_return(chat_history_service)
    end

    it "calls insert_to_chat_history on the chat history service" do
      expect(chat_history_service).to receive(:insert_to_chat_history).with(query, response)

      test_instance.save_chat_history!(query, response)
    end

    it "passes the query and response parameters correctly" do
      allow(chat_history_service).to receive(:insert_to_chat_history)

      test_instance.save_chat_history!(query, response)

      expect(chat_history_service).to have_received(:insert_to_chat_history).with(query, response)
    end

    context "with different types of queries and responses" do
      it "handles empty strings" do
        expect(chat_history_service).to receive(:insert_to_chat_history).with("", response)
        test_instance.save_chat_history!("", response)
      end

      it "handles nil values" do
        expect(chat_history_service).to receive(:insert_to_chat_history).with(nil, response)
        test_instance.save_chat_history!(nil, response)
      end

      it "handles long text" do
        long_query = "This is a very long query that might contain a lot of text and should be handled properly by "\
         "the chat history service without any issues or truncation."
        long_response = "This is a very long response that might contain a lot of text"\
         "and should be handled properly by the chat history service without any issues or truncation."

        expect(chat_history_service).to receive(:insert_to_chat_history).with(long_query, long_response)
        test_instance.save_chat_history!(long_query, long_response)
      end

      it "handles special characters" do
        special_query = "What's the weather like? 🌤️"
        special_response = "It's sunny! ☀️ Temperature: 75°F"

        expect(chat_history_service).to receive(:insert_to_chat_history).with(special_query, special_response)
        test_instance.save_chat_history!(special_query, special_response)
      end
    end

    context "when called multiple times" do
      it "uses the same chat history service instance" do
        # First call to chat_history_service happens in the before block
        # Second call happens when we call save_chat_history!
        allow(chat_history_service).to receive(:insert_to_chat_history)

        test_instance.save_chat_history!(query, response)
        test_instance.save_chat_history!("Another query", "Another response")

        expect(chat_history_service).to have_received(:insert_to_chat_history).twice
      end
    end
  end

  describe "integration with ChatHistoryService" do
    let(:query) { "How do I reset my password?" }
    let(:response) { "To reset your password, go to the settings page." }

    it "actually creates chat messages when save_chat_history! is called" do
      # Don't mock the service, let it work with real data
      allow(test_instance).to receive(:chat_history_service).and_call_original

      expect do
        test_instance.save_chat_history!(query, response)
      end.to change(ChatMessage, :count).by(2)

      # Verify the messages were created correctly
      user_message = ChatMessage.find_by(role: "user")
      assistant_message = ChatMessage.find_by(role: "assistant")

      expect(user_message).to be_present
      expect(user_message.content).to eq(query)
      expect(user_message.workspace_id).to eq(workspace.id)
      expect(user_message.visual_component_id).to eq(visual_component.id)
      expect(user_message.session_id).to eq(data_app_session.id)

      expect(assistant_message).to be_present
      expect(assistant_message.content).to eq(response)
      expect(assistant_message.workspace_id).to eq(workspace.id)
      expect(assistant_message.visual_component_id).to eq(visual_component.id)
      expect(assistant_message.session_id).to eq(data_app_session.id)
    end

    it "updates the session title when it's the first message" do
      allow(test_instance).to receive(:chat_history_service).and_call_original

      test_instance.save_chat_history!(query, response)

      data_app_session.reload
      expect(data_app_session.title).to eq(query)
    end

    it "doesn't update session title for subsequent messages" do
      allow(test_instance).to receive(:chat_history_service).and_call_original

      # First message should set the title
      test_instance.save_chat_history!(query, response)
      data_app_session.reload
      original_title = data_app_session.title

      # Second message shouldn't change the title
      test_instance.save_chat_history!("Another query", "Another response")
      data_app_session.reload

      expect(data_app_session.title).to eq(original_title)
    end
  end

  describe "error handling" do
    let(:query) { "Test query" }
    let(:response) { "Test response" }
    let(:chat_history_service) { instance_double(ChatHistoryService) }

    before do
      allow(test_instance).to receive(:chat_history_service).and_return(chat_history_service)
    end

    it "propagates errors from the ChatHistoryService" do
      error_message = "Database connection failed"
      allow(chat_history_service).to receive(:insert_to_chat_history).and_raise(StandardError, error_message)

      expect do
        test_instance.save_chat_history!(query, response)
      end.to raise_error(StandardError, error_message)
    end

    it "handles database transaction errors" do
      allow(chat_history_service).to receive(:insert_to_chat_history)
        .and_raise(ActiveRecord::RecordInvalid.new(visual_component))

      expect do
        test_instance.save_chat_history!(query, response)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "memoization behavior" do
    it "creates the service only once per instance" do
      expect(ChatHistoryService).to receive(:new).once.and_call_original

      test_instance.chat_history_service
      test_instance.chat_history_service
      test_instance.chat_history_service
    end

    it "creates different services for different instances" do
      another_instance = test_class.new(data_app_session, visual_component)

      expect(ChatHistoryService).to receive(:new).twice.and_call_original

      test_instance.chat_history_service
      another_instance.chat_history_service
    end
  end
end
