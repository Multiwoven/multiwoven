# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Transformers::Embeddings::HuggingFace, type: :model do
  let(:embedding_config) { { "model" => "all-MiniLM-L6-v2", "api_key" => "fake_api_key" }.with_indifferent_access }
  let(:hugging_face_embedding) { described_class.new(embedding_config) }
  let(:sample_text) { "This is a sample text." }

  describe "#generate_embedding" do
    context "when the Hugging Face request is successful" do
      let(:fake_response) { [0.1, 0.2, 0.3].to_json }

      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: fake_response, code: "200"))
      end

      it "returns the embedding from the response" do
        result = hugging_face_embedding.generate_embedding(sample_text)
        expect(result).to eq([0.1, 0.2, 0.3])
      end

      it "calls HttpClient.request with the correct arguments" do
        url = "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"
        http_method = "POST"
        payload = { inputs: sample_text, normalize: true }
        headers = { "Authorization" => "Bearer #{embedding_config[:api_key]}", "Content-Type" => "application/json" }

        expect(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .with(url, http_method, payload:, headers:)
          .and_return(double("response", body: fake_response, code: "200"))

        hugging_face_embedding.generate_embedding(sample_text)
      end
    end

    context "when the Hugging Face request fails" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: "Error", code: "500"))
      end

      it "raises a HuggingFaceError with the failure message" do
        expect do
          hugging_face_embedding.generate_embedding(sample_text)
        end.to raise_error(ReverseEtl::Transformers::Embeddings::HuggingFace::HuggingFaceError,
                           /Hugging Face request failed with status 500: Error/)
      end
    end

    context "when there is a JSON parsing error" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_return(double("response", body: "invalid", code: "200"))
      end

      it "raises a HuggingFaceError with the parse error message" do
        expect do
          hugging_face_embedding.generate_embedding(sample_text)
        end.to raise_error(ReverseEtl::Transformers::Embeddings::HuggingFace::HuggingFaceError,
                           /Failed to parse response from Hugging Face/)
      end
    end

    context "when there is a general error during the Hugging Face request" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request)
          .and_raise(StandardError.new("Something went wrong"))
      end

      it "raises a HuggingFaceError with the general error message" do
        expect do
          hugging_face_embedding.generate_embedding(sample_text)
        end.to raise_error(ReverseEtl::Transformers::Embeddings::HuggingFace::HuggingFaceError,
                           /An error occurred while making the Hugging Face request: Something went wrong/)
      end
    end
  end
end
