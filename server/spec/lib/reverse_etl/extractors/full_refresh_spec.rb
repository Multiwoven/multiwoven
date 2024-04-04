# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::FullRefresh do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:, sync_mode: "full_refresh") }
  let(:sync_run1) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run2) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end

  let(:sync_run_pending) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "pending")
  end
  let(:activity) { instance_double("ExtractorActivity") }

  let(:client) { Multiwoven::Integrations::Source::Snowflake::Client.new }
  let(:record1) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                  "first_name" => "John", "Last Name" => "Doe" },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end
  let(:record2) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 2, "email" => "test2@mail.com",
                                                                  "first_name" => "Mark", "Last Name" => "Doe" },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end
  let(:record3) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 2, "email" => "test2@mail.com",
                                                                  "first_name" => "Natalie", "Last Name" => "Doe" },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end

  let(:records) { [record1, record2] }

  before do
    sync.model.update(primary_key: "id")
    allow(client).to receive(:read).and_return(records)
    allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield(records, 1)
    allow(sync_run1.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
    allow(activity).to receive(:heartbeat)
    allow(activity).to receive(:cancel_requested).and_return(false)
  end

  describe "#read" do
    context "performs a full refresh" do
      it "performs a full refresh and updates the sync run" do
        expect(sync_run1).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity)
        # expect(subject).to receive(:flush_records)
        expect(subject).not_to receive(:log_mismatch_error)
        subject.read(sync_run1.id, activity)
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(2)
        expect(sync_run1).to have_state(:queued)
        sync_run1.sync_records.each do |sync_record|
          expect(sync_record.action).to eq("destination_insert"),
                                        "Expected action to be 'destination_insert' but was '#{sync_record.action}'
                                         for sync_record with primary_key #{sync_record.primary_key}"
        end

        expect(SyncRecord.where(sync_id: sync_run1.sync_id).count).to eq(2)
      end

      it "with duplicate primary key and different finger print" do
        expect(SyncRecord.where(sync_id: sync_run1.sync_id).count).to eq(0)
        allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield([record2, record3], 1)
        expect(sync_run2).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity)
        expect(subject).to receive(:log_mismatch_error)
        subject.read(sync_run2.id, activity)
        sync_run2.reload
        sync_records = SyncRecord.where(sync_id: sync_run2.sync_id)
        expect(sync_records.first.record["first_name"]).to eq("Mark")
        expect(sync_records.count).to eq(1)
        expect(sync_run2).to have_state(:queued)
      end
    end

    context "with invalid state" do
      it "creates a new sync record" do
        expect(sync_run_pending).to have_state(:pending)
        expect(subject).not_to receive(:heartbeat)
        expect(subject).not_to receive(:setup_source_client)
        expect(subject).not_to receive(:process_records)
        subject.read(sync_run_pending.id, activity)
        expect(sync_run_pending).to have_state(:pending)
      end
    end
  end
end
