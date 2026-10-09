# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Processors::Text::TokenChunker do
  let(:processor) { described_class.new }
  let(:content) { "This is a test content for token chunking" }
  let(:metadata) do
    {
      file_name: "test.pdf",
      file_type: "PDF",
      file_created_date: Time.current.iso8601,
      file_modified_date: Time.current.iso8601
    }
  end
  let(:mock_tokeniser) { double("tokeniser") }

  describe "#process" do
    context "with invalid config" do
      it "raises TypeError when model is blank" do
        expect { processor.process({ model: nil, provider: "open_ai" }, content) }
          .to raise_error(TypeError, "Model is required")
      end

      it "raises TypeError when model is unsupported" do
        expect { processor.process({ model: "unknown-model", provider: "open_ai" }, content) }
          .to raise_error(TypeError, /not supported/)
      end

      it "raises TypeError when provider is blank" do
        expect { processor.process({ model: "text-embedding-ada-002", provider: nil }, content) }
          .to raise_error(TypeError, "Provider is required")
      end

      it "raises TypeError when provider is unsupported" do
        allow(Tiktoken).to receive(:encoding_for_model).and_return(mock_tokeniser)
        expect { processor.process({ model: "text-embedding-ada-002", provider: "unknown_provider" }, content) }
          .to raise_error(TypeError, /not supported/)
      end
    end

    context "with open_ai provider" do
      let(:model) { "text-embedding-ada-002" }
      let(:chunk_config) { { model:, provider: "open_ai", chunk_size: 8191 } }

      before do
        allow(Tiktoken).to receive(:encoding_for_model).with(model).and_return(mock_tokeniser)
      end

      context "when text is within the token limit" do
        before do
          allow(mock_tokeniser).to receive(:encode).and_return(Array.new(100, 1))
          allow(mock_tokeniser).to receive(:decode).and_return("decoded text")
        end

        it "returns a single chunk as a string" do
          result = processor.process(chunk_config, content)
          expect(result).to be_an(Array)
          expect(result.length).to eq(1)
          expect(result.first).to be_a(String)
        end
      end

      context "when text exceeds the token limit" do
        before do
          allow(mock_tokeniser).to receive(:encode).and_return(Array.new(9000, 1))
          allow(mock_tokeniser).to receive(:decode).and_return("decoded chunk text")
        end

        it "splits text into multiple string chunks" do
          result = processor.process(chunk_config, content)
          expect(result).to be_an(Array)
          expect(result.length).to be > 1
          expect(result.first).to be_a(String)
        end
      end
    end

    context "with hugging_face provider" do
      let(:model) { "all-MiniLM-L6-v2" }
      let(:chunk_config) { { model:, provider: "hugging_face", chunk_size: 256 } }
      let(:mock_encode_result) { double("encode_result", tokens: Array.new(100, "token")) }

      before do
        allow(Tokenizers::Tokenizer).to receive(:from_pretrained)
          .with("sentence-transformers/#{model}")
          .and_return(mock_tokeniser)
        allow(mock_tokeniser).to receive(:encode).and_return(mock_encode_result)
        allow(mock_tokeniser).to receive(:decode).and_return(%w[decoded chunk])
      end

      context "when text is within the token limit" do
        it "returns a single string chunk" do
          result = processor.process(chunk_config, content)
          expect(result).to be_an(Array)
          expect(result.length).to eq(1)
          expect(result.first).to be_a(String)
        end
      end

      context "when text exceeds the token limit" do
        let(:mock_encode_result) { double("encode_result", tokens: Array.new(300, "token")) }

        it "splits text into multiple string chunks" do
          result = processor.process(chunk_config, content)
          expect(result).to be_an(Array)
          expect(result.length).to be > 1
          expect(result.first).to be_a(String)
        end
      end
    end
  end

  describe "#get_tokens" do
    context "with open_ai provider" do
      before do
        allow(Tiktoken).to receive(:encoding_for_model).with("text-embedding-ada-002").and_return(mock_tokeniser)
        allow(mock_tokeniser).to receive(:encode).and_return([1, 2, 3])
        processor.instance_variable_set(:@model, "text-embedding-ada-002")
        processor.instance_variable_set(:@provider, "open_ai")
        processor.instance_variable_set(:@tokeniser, mock_tokeniser)
      end

      it "calls encode and returns the token array directly" do
        expect(processor.send(:get_tokens, "hello")).to eq([1, 2, 3])
      end
    end

    context "with hugging_face provider" do
      let(:encode_result) { double("encode_result", tokens: %w[tok1 tok2]) }

      before do
        allow(mock_tokeniser).to receive(:encode).and_return(encode_result)
        processor.instance_variable_set(:@model, "all-MiniLM-L6-v2")
        processor.instance_variable_set(:@provider, "hugging_face")
        processor.instance_variable_set(:@tokeniser, mock_tokeniser)
      end

      it "calls encode and returns the .tokens array" do
        expect(processor.send(:get_tokens, "hello")).to eq(%w[tok1 tok2])
      end
    end
  end

  describe "#tokens_to_text_chunks" do
    context "with open_ai provider" do
      before do
        allow(mock_tokeniser).to receive(:decode).and_return("decoded text")
        processor.instance_variable_set(:@provider, "open_ai")
        processor.instance_variable_set(:@tokeniser, mock_tokeniser)
      end

      it "decodes each token slice and returns strings" do
        tokens = Array.new(20, 1)
        result = processor.send(:tokens_to_text_chunks, tokens, 10)
        expect(result.length).to eq(2)
        expect(result.first).to eq("decoded text")
      end
    end

    context "with hugging_face provider" do
      before do
        allow(mock_tokeniser).to receive(:decode).and_return(%w[word1 word2])
        processor.instance_variable_set(:@provider, "hugging_face")
        processor.instance_variable_set(:@tokeniser, mock_tokeniser)
      end

      it "decodes and joins tokens with a space" do
        tokens = Array.new(20, "tok")
        result = processor.send(:tokens_to_text_chunks, tokens, 10)
        expect(result.length).to eq(2)
        expect(result.first).to eq("word1 word2")
      end
    end
  end
end
