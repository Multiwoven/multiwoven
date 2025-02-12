# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::Embeddings::EmbeddingService, type: :model do
  let(:embedding_config) { { mode: "open_ai", api_key: "fake_api_key", model: "text-embedding-ada-002" } }
  let(:embedding_service) { described_class.new(embedding_config:) }
  let(:sample_text) { "This is a sample text." }
  let(:open_ai_service) { instance_double("ReverseEtl::Transformers::Embeddings::OpenAi") }

  describe "#generate_embedding" do
    context "when the embedding service is available" do
      before do
        allow(ReverseEtl::Transformers::Embeddings::OpenAi)
          .to receive(:new).with(embedding_config).and_return(open_ai_service)
        allow(open_ai_service).to receive(:generate_embedding).with(sample_text).and_return([0.1, 0.2, 0.3])
      end

      it "calls the OpenAi service's generate_embedding method" do
        result = embedding_service.generate_embedding(sample_text)

        expect(result).to eq([0.1, 0.2, 0.3])
        expect(open_ai_service).to have_received(:generate_embedding).with(sample_text)
      end
    end

    context "when the mode is not supported" do
      let(:invalid_embedding_config) { { mode: "test_mode", api_key: "fake_api_key", model: "text-embedding-ada-002" } }
      let(:invalid_embedding_service) { described_class.new(embedding_config: invalid_embedding_config) }

      it "raises an error when the service class cannot be found" do
        expect do
          invalid_embedding_service.generate_embedding(sample_text)
        end.to raise_error(
          StandardError,
          "Embedding mode 'test_mode' is not supported. Class 'ReverseEtl::Transformers::Embeddings::TestMode' " \
            "not found."
        )
      end
    end
  end
end
