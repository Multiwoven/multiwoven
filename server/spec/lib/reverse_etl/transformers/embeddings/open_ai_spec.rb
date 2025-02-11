# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::Embeddings::OpenAi, type: :model do
  let(:embedding_config) { { mode: "openai", api_key: "fake_api_key", model: "text-embedding-ada-002" } }
  let(:openai_embedding) { described_class.new(embedding_config) }
  let(:sample_text) { "This is a sample text." }

  describe "#generate_embedding" do
    context "when the OpenAI request is successful" do
      let(:fake_response) { { "data" => [{ "embedding" => [0.1, 0.2, 0.3] }] }.to_json }

      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: fake_response, code: "200"))
      end

      it "returns the embedding from the response" do
        result = openai_embedding.generate_embedding(sample_text)
        expect(result).to eq([0.1, 0.2, 0.3])
      end

      it "calls HttpClient.request with the correct arguments" do
        url = "https://api.openai.com/v1/embeddings"
        http_method = "POST"
        payload = { model: embedding_config[:model], input: sample_text }
        headers = {
          "Authorization" => "Bearer #{embedding_config[:api_key]}",
          "Content-Type" => "application/json"
        }

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url, http_method, payload:, headers:)
          .and_return(double("response", body: fake_response, code: "200"))

        openai_embedding.generate_embedding(sample_text)
      end
    end

    context "when the OpenAI request fails" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: "Error", code: "500"))
      end

      it "raises an OpenAIError with the failure message" do
        expect do
          openai_embedding.generate_embedding(sample_text)
        end
        .to raise_error(ReverseEtl::Transformers::Embeddings::OpenAi::OpenAIError,
                        /OpenAI request failed with status 500/)
      end
    end

    context "when there is a JSON parsing error" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: "invalid json", code: "200"))
      end

      it "raises an OpenAIError with the parse error message" do
        expect do
          openai_embedding.generate_embedding(sample_text)
        end.to raise_error(ReverseEtl::Transformers::Embeddings::OpenAi::OpenAIError,
                           /Failed to parse response from OpenAI/)
      end
    end

    context "when there is a general error during the OpenAI request" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_raise(StandardError.new("Something went wrong"))
      end

      it "raises an OpenAIError with the general error message" do
        expect do
          openai_embedding.generate_embedding(sample_text)
        end.to raise_error(
          ReverseEtl::Transformers::Embeddings::OpenAi::OpenAIError, /An error occurred while making the OpenAI request/
        )
      end
    end
  end
end
