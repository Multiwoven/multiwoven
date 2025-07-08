# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::WebScraping do
  let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync_run1) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:activity) { instance_double("ExtractorActivity") }

  let(:client) { instance_double(Multiwoven::Integrations::Source::Snowflake::Client) }
  let(:record1) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(
      data: {
        markdown: "Some content",
        markdown_hash: "chunk-1",
        metadata: "{\"meta\": \"data\", \"url\": \"Test.com\"}",
        url: "Test.com"
      },
      emitted_at: DateTime.now.to_i
    ).to_multiwoven_message
  end
  let(:chunk_processor) { instance_double("ReverseEtl::Processors::Text::ChunkProcessor") }
  let(:chunked_records) do
    [
      {
        element_id: "chunk-1",
        text: "Some extracted content"
      }
    ]
  end

  let(:chunked_records2) do
    [
      {
        element_id: "chunk-1",
        text: "Some New extracted content"
      }
    ]
  end

  before do
    sync.model.update(primary_key: "markdown_hash", query: "SELECT * FROM web_scraping_data")
    allow_any_instance_of(described_class).to receive(:setup_source_client).and_return(client)
    allow(client).to receive(:read).and_return([record1])
    allow(sync_run1.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
    allow(activity).to receive(:heartbeat).and_return(activity)
    allow(activity).to receive(:cancel_requested).and_return(false)
    allow(ReverseEtl::Processors::Text::ChunkProcessor).to receive(:new).and_return(chunk_processor)
    allow(chunk_processor).to receive(:process).and_return(chunked_records)
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

        data = {
          markdown: chunked_records[0][:text],
          markdown_hash: chunked_records[0][:element_id],
          metadata: record1.record.data[:metadata],
          url: JSON.parse(record1.record.data[:metadata])["url"]
        }

        initial_sync_record = sync_run1.sync_records.find_by(primary_key: record1.record.data[:markdown_hash])
        expect(initial_sync_record.fingerprint).to eq(subject.send(:generate_fingerprint, data))
        expect(initial_sync_record.action).to eq("destination_insert")

        modified_record1 = Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: record1.record.data.merge({ markdown: "new_value" }),
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message

        allow(client).to receive(:read).and_return([modified_record1])
        allow(chunk_processor).to receive(:process).and_return(chunked_records2)

        data2 = {
          markdown: chunked_records2[0][:text],
          markdown_hash: chunked_records2[0][:element_id],
          metadata: modified_record1.record.data[:metadata],
          url: JSON.parse(modified_record1.record.data[:metadata])["url"]
        }

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

        updated_sync_record = sync_run2.sync_records.find_by(primary_key: record1.record.data[:markdown_hash])
        expect(updated_sync_record.fingerprint).not_to eq(initial_sync_record.fingerprint)
        expect(updated_sync_record.action).to eq("destination_update")
        expect(updated_sync_record.record).to eq(data2.with_indifferent_access)
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
  end
end
