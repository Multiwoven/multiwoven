# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Processors::Text::ChunkProcessor do
  let(:processor) { described_class.new }
  let(:chunk_config) do
    {
      chunk_size: 1000,
      chunk_overlap: 200
    }
  end
  let(:content) { "This is a test content" }
  let(:metadata) do
    {
      file_name: "test.pdf",
      file_path: "/tmp/test.pdf",
      file_type: "PDF",
      size: 123,
      file_created_date: Time.current.iso8601,
      file_modified_date: Time.current.iso8601
    }
  end
  let(:chunks) { %w[chunk1 chunk2] }
  let(:mock_chunk_processor) { instance_double(ReverseEtl::Processors::Text::LangchainRb) }

  before do
    allow(ReverseEtl::Processors::Text::LangchainRb).to receive(:new).and_return(mock_chunk_processor)
    allow(mock_chunk_processor).to receive(:process).and_return(chunks)
  end

  describe "#process" do
    context "processor selection (legacy config — no model/provider)" do
      context "when CHUNK_PROCESSOR is not set" do
        before { ENV["CHUNK_PROCESSOR"] = nil }

        it "uses LangchainRb as default processor" do
          expect(ReverseEtl::Processors::Text::LangchainRb).to receive(:new).and_return(mock_chunk_processor)
          processor.process(chunk_config, content, metadata)
        end
      end

      context "when CHUNK_PROCESSOR is set to langchain_rb" do
        before { ENV["CHUNK_PROCESSOR"] = "langchain_rb" }
        after  { ENV["CHUNK_PROCESSOR"] = nil }

        it "uses the specified processor" do
          expect(ReverseEtl::Processors::Text::LangchainRb).to receive(:new).and_return(mock_chunk_processor)
          processor.process(chunk_config, content, metadata)
        end
      end

      context "when CHUNK_PROCESSOR refers to a non-existent class" do
        before { ENV["CHUNK_PROCESSOR"] = "non_existent_processor" }
        after  { ENV["CHUNK_PROCESSOR"] = nil }

        it "raises NameError" do
          expect { processor.process(chunk_config, content, metadata) }.to raise_error(NameError)
        end
      end
    end

    context "processor selection (non-legacy config — has model/provider/chunk_size)" do
      let(:mock_token_chunker) { instance_double(ReverseEtl::Processors::Text::TokenChunker) }
      let(:non_legacy_config) { { model: "text-embedding-ada-002", provider: "open_ai", chunk_size: 8191 } }

      before do
        allow(ReverseEtl::Processors::Text::TokenChunker).to receive(:new).and_return(mock_token_chunker)
        allow(mock_token_chunker).to receive(:process).and_return(chunks)
      end

      it "uses TokenChunker" do
        expect(ReverseEtl::Processors::Text::TokenChunker).to receive(:new).and_return(mock_token_chunker)
        processor.process(non_legacy_config, content, metadata)
      end
    end

    it "processes content into chunks with metadata" do
      result = processor.process(chunk_config, content, metadata)
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to include(
        element_id: Digest::MD5.hexdigest("chunk1"),
        text: "chunk1",
        created_date: metadata[:file_created_date],
        modified_date: metadata[:file_modified_date],
        filename: metadata[:file_name],
        filetype: metadata[:file_type],
        created_at: kind_of(Time)
      )
    end

    it "uses default chunk size and overlap if not provided" do
      processor.process({}, content, metadata)
      expect(mock_chunk_processor).to have_received(:process).with(
        { chunk_size: 1000, chunk_overlap: 200 },
        content
      )
    end

    context "when processing raises an error" do
      before do
        allow(mock_chunk_processor).to receive(:process).and_raise(StandardError, "Processing failed")
      end

      it "raises ChunkProcessingError" do
        expect do
          processor.process(chunk_config, content, metadata)
        end.to raise_error(StandardError,
                           "Processing failed")
      end
    end
  end

  describe "#legacy?" do
    it "returns true when model and provider are both blank" do
      expect(processor.send(:legacy?, {})).to be true
    end

    it "returns true when only chunk_size is present (no model/provider)" do
      expect(processor.send(:legacy?, { chunk_size: 8191 })).to be true
    end

    it "returns false when model is present" do
      expect(processor.send(:legacy?, { model: "text-embedding-ada-002" })).to be false
    end

    it "returns false when provider is present" do
      expect(processor.send(:legacy?, { provider: "open_ai" })).to be false
    end

    it "returns false when both model and provider are present" do
      expect(processor.send(:legacy?,
                            { model: "text-embedding-ada-002", provider: "open_ai", chunk_size: 8191 })).to be false
    end
  end

  describe "#format_chunks" do
    it "formats chunks with metadata" do
      result = processor.send(:format_chunks, chunks, metadata)
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to include(
        element_id: Digest::MD5.hexdigest("chunk1"),
        text: "chunk1",
        created_date: metadata[:file_created_date],
        modified_date: metadata[:file_modified_date],
        filename: metadata[:file_name],
        filetype: metadata[:file_type],
        created_at: kind_of(Time)
      )
    end

    it "generates unique element_id for each chunk" do
      result = processor.send(:format_chunks, chunks, metadata)
      expect(result.first[:element_id]).not_to eq(result.last[:element_id])
    end

    it "handles missing metadata gracefully" do
      result = processor.send(:format_chunks, chunks, {})
      expect(result.first).to include(
        element_id: Digest::MD5.hexdigest("chunk1"),
        text: "chunk1",
        created_at: kind_of(Time)
      )
      expect(result.first[:created_date]).to be_nil
      expect(result.first[:modified_date]).to be_nil
      expect(result.first[:file_name]).to be_nil
      expect(result.first[:file_type]).to be_nil
    end
  end
end
