# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::WebScraping do
  let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:standard_configuration) do
    [{ "mapping_type" => "standard", "from" => "markdown", "to" => "markdown" }]
  end
  let(:vector_configuration) do
    [
      {
        "mapping_type" => "vector",
        "from" => "markdown",
        "to" => "embedding",
        "embedding_config" => {
          "model" => "text-embedding-ada-002",
          "mode" => "open_ai",
          "provider" => "open_ai"
        }
      }
    ]
  end
  let(:sync) { create(:sync, source:, destination:, configuration: standard_configuration) }
  let(:sync_run1) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:activity) { instance_double("ExtractorActivity") }

  let(:client) { instance_double(Multiwoven::Integrations::Source::Snowflake::Client) }
  let(:record1) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(
      data: { "id" => 1, "email" => "test1@mail.com", "first_name" => "John", "Last Name" => "Doe" },
      emitted_at: DateTime.now.to_i
    ).to_multiwoven_message
  end

  before do
    sync.model.update(primary_key: "id")
    allow_any_instance_of(described_class).to receive(:setup_source_client).and_return(client)
    allow(client).to receive(:read).and_return([record1])
    allow(sync_run1.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
    allow(activity).to receive(:heartbeat).and_return(activity)
    allow(activity).to receive(:cancel_requested).and_return(false)
  end

  describe "#read" do
    subject { described_class.new }

    context "when there is a new record" do
      it "creates a new sync record" do
        expect(subject).to receive(:heartbeat).exactly(:once)
        expect { subject.read(sync_run1.id, activity) }.to change { sync_run1.sync_records.count }.by(1)
        sync_run1.reload
        expect(sync_run1.current_offset).to eq(0)
        expect(sync_run1.total_query_rows).to eq(1)
        expect(sync_run1.skipped_rows).to eq(0)
      end
    end

    context "when an existing record is updated" do
      it "updates the existing sync record with fingerprint change" do
        # First sync run
        expect(sync_run1).to have_state(:started)
        subject.read(sync_run1.id, activity)
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(1)
        expect(sync_run1).to have_state(:queued)
        expect(sync_run1.current_offset).to eq(0)
        expect(sync_run1.total_query_rows).to eq(1)
        expect(sync_run1.skipped_rows).to eq(0)

        initial_sync_record = sync_run1.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(initial_sync_record.fingerprint).to eq(subject.send(:generate_fingerprint, record1.record.data))
        expect(initial_sync_record.action).to eq("destination_insert")

        modified_record1 = Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: record1.record.data.merge({ "modified_field" => "new_value" }),
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message

        allow(client).to receive(:read).and_return([modified_record1])

        # Second sync run
        sync_run2 = create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model,
                                      status: "started")
        expect(sync_run2).to have_state(:started)
        subject.read(sync_run2.id, activity)
        sync_run2.reload
        expect(sync_run2).to have_state(:queued)
        expect(sync_run2.sync_records.count).to eq(1)
        expect(sync_run2.current_offset).to eq(0)
        expect(sync_run2.total_query_rows).to eq(1)
        expect(sync_run2.skipped_rows).to eq(0)

        updated_sync_record = sync_run2.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(updated_sync_record.fingerprint).not_to eq(initial_sync_record.fingerprint)
        expect(updated_sync_record.action).to eq("destination_update")
        expect(updated_sync_record.record).to eq(modified_record1.record.data)
      end

      it "handles heartbeat timeout and updates sync run state" do
        expect(sync_run1).to have_state(:started)
        allow(activity).to receive(:cancel_requested).and_return(true)
        expect { subject.read(sync_run1.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(0)
        expect(sync_run1).to have_state(:failed)
      end
    end

    context "when sync run is in pending state" do
      let(:sync_run_pending) do
        create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "pending")
      end

      it "does not process the record" do
        expect(sync_run_pending).to have_state(:pending)
        expect(subject).not_to receive(:heartbeat)
        expect(subject).not_to receive(:setup_source_client)
        expect(subject).not_to receive(:process_record)
        subject.read(sync_run_pending.id, activity)
        expect(sync_run_pending).to have_state(:pending)
      end
    end

    context "when vector mapping is present" do
      let(:sync) { create(:sync, source:, destination:, configuration: vector_configuration) }
      let(:sync_run_vector) do
        create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
      end

      before do
        sync.model.update(primary_key: "markdown_hash", query: "SELECT * FROM web_scraping_data")
      end

      it "uses token chunking and creates sync records" do
        expect(chunk_processor).to receive(:process)
          .with({ model: "text-embedding-ada-002", provider: "open_ai", chunk_size: 8191 }, "Some content")
          .and_return(chunked_records)
        expect { subject.read(sync_run_vector.id, activity) }.to change { sync_run_vector.sync_records.count }.by(1)
        sync_run_vector.reload
        expect(sync_run_vector.total_query_rows).to eq(1)
        expect(sync_run_vector.skipped_rows).to eq(0)
      end
    end
  end

  describe "#generate_chunks" do
    subject { described_class.new }

    context "when no vector mapping is present" do
      it "calls process on chunk_processor with default chunk config" do
        expect(chunk_processor).to receive(:process)
          .with({ chunk_size: 1000, chunk_overlap: 200 }, "Some content")
          .and_return(chunked_records)
        result = subject.send(:generate_chunks, sync_run1, "Some content")
        expect(result).to eq(chunked_records)
      end
    end

    context "when a vector mapping is present" do
      let(:sync) { create(:sync, source:, destination:, configuration: vector_configuration) }
      let(:sync_run_vector) do
        create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
      end

      before do
        sync.model.update(primary_key: "markdown_hash", query: "SELECT * FROM web_scraping_data")
      end

      it "calls ChunkProcessor#process with model, provider, and chunk_size from embedding_config" do
        expect(chunk_processor).to receive(:process)
          .with({ model: "text-embedding-ada-002", provider: "open_ai", chunk_size: 8191 }, "Some content")
          .and_return(chunked_records)
        result = subject.send(:generate_chunks, sync_run_vector, "Some content")
        expect(result).to eq(chunked_records)
      end
    end

    context "when multiple vector mappings are present" do
      let(:multi_vector_configuration) do
        [
          {
            "mapping_type" => "vector",
            "from" => "markdown",
            "to" => "embedding_1",
            "embedding_config" => { "model" => "text-embedding-ada-002", "mode" => "open_ai" }
          },
          {
            "mapping_type" => "vector",
            "from" => "markdown",
            "to" => "embedding_2",
            "embedding_config" => { "model" => "all-MiniLM-L6-v2", "mode" => "hugging_face" }
          }
        ]
      end
      let(:sync) { create(:sync, source:, destination:, configuration: multi_vector_configuration) }
      let(:sync_run_multi) do
        create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
      end

      before do
        sync.model.update(primary_key: "markdown_hash", query: "SELECT * FROM web_scraping_data")
      end

      it "uses the model with the smallest token limit" do
        expect(chunk_processor).to receive(:process)
          .with({ model: "all-MiniLM-L6-v2", provider: "hugging_face", chunk_size: 256 }, "Some content")
          .and_return(chunked_records)
        result = subject.send(:generate_chunks, sync_run_multi, "Some content")
        expect(result).to eq(chunked_records)
      end
    end

    context "when chunk processing raises a StandardError" do
      before do
        allow(chunk_processor).to receive(:process).and_raise(StandardError, "processing failed")
      end

      it "raises ChunkProcessingError" do
        expect { subject.send(:generate_chunks, sync_run1, "Some content") }
          .to raise_error(ReverseEtl::Extractors::ChunkProcessingError, /processing failed/)
      end
    end
  end

  describe "#fetch_records" do
    subject { described_class.new }

    context "when source returns nil" do
      before do
        allow(client).to receive(:read).and_return(nil)
      end

      it "raises a RuntimeError" do
        expect { subject.send(:fetch_records, sync_run1) }
          .to raise_error(RuntimeError, /Expected record in the result/)
      end
    end

    context "when source returns a non-array" do
      before do
        allow(client).to receive(:read).and_return("unexpected string")
      end

      it "raises a RuntimeError" do
        expect { subject.send(:fetch_records, sync_run1) }
          .to raise_error(RuntimeError, /Expected record in the result/)
      end
    end

    context "when source returns a valid array" do
      it "returns the result" do
        result = subject.send(:fetch_records, sync_run1)
        expect(result).to eq([record1])
      end
    end
  end

  describe "#build_record" do
    subject { described_class.new }

    let(:message) { { "text" => "Hello world", "element_id" => "abc123" } }
    let(:metadata) { "{\"url\": \"https://example.com\", \"source\": \"test\"}" }

    it "maps text to markdown and element_id to markdown_hash" do
      record = subject.send(:build_record, message, metadata)
      expect(record.data[:markdown]).to eq("Hello world")
      expect(record.data[:markdown_hash]).to eq("abc123")
    end

    it "parses the url from metadata JSON" do
      record = subject.send(:build_record, message, metadata)
      expect(record.data[:url]).to eq("https://example.com")
    end

    it "stores the raw metadata string" do
      record = subject.send(:build_record, message, metadata)
      expect(record.data[:metadata]).to eq(metadata)
    end

    it "returns a RecordMessage" do
      record = subject.send(:build_record, message, metadata)
      expect(record).to be_a(Multiwoven::Integrations::Protocol::RecordMessage)
    end
  end
end
