# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::IncrementalDelta do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync_run1) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run2) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run3) do
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
                                                                  "first_name" => "Mark", "Last Name" => "Doe" },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end

  let(:records) { [record1, record2] }

  before do
    sync.model.update(primary_key: "id")
    allow(client).to receive(:read).and_return(records)
    allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield(records, 1, nil)
    allow(sync_run1.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
    allow(activity).to receive(:heartbeat)
    allow(activity).to receive(:cancel_requested).and_return(false)
  end

  describe "#read" do
    context "when there is a new record" do
      it "creates a new sync record" do
        expect(subject).to receive(:heartbeat).once.with(activity)
        expect { subject.read(sync_run1.id, activity) }.to change(sync_run1.sync_records, :count).by(2)
      end
    end

    context "when an existing record is updated" do
      it "updates the existing sync record with fingerprint change" do
        # First sync run
        expect(sync_run1).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity)
        subject.read(sync_run1.id, activity)
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(2)
        expect(sync_run1).to have_state(:queued)

        initial_sync_record = sync_run1.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(initial_sync_record.fingerprint).to eq(subject.send(:generate_fingerprint, record1.record.data))
        expect(initial_sync_record.action).to eq("destination_insert")

        initial_sync_record_second = sync_run1.sync_records.find_by(primary_key: record2.record.data["id"])
        expect(initial_sync_record_second.fingerprint).to eq(subject.send(:generate_fingerprint, record2.record.data))
        expect(initial_sync_record_second.action).to eq("destination_insert")

        modified_record1 = Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: record1.record.data.merge({ "modified_field" => "new_value" }),
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message

        allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield([modified_record1, record2], 1,
                                                                                       "2022-01-01")

        # Second sync run
        expect(sync_run2).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity)
        subject.read(sync_run2.id, activity)
        sync_run2.reload
        expect(sync_run2).to have_state(:queued)
        expect(sync_run2.sync.current_cursor_field).to eql("2022-01-01")

        updated_sync_record = sync_run2.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(sync_run2.sync_records.count).to eq(1)
        expect(updated_sync_record.fingerprint).not_to eq(initial_sync_record.fingerprint)
        expect(updated_sync_record.action).to eq("destination_update")
        expect(updated_sync_record.record).to eq(modified_record1.record.data)

        allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield([record2, record3], 1,
                                                                                       "2022-01-02")

        # Third sync run with same record
        expect(sync_run3).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity)
        subject.read(sync_run3.id, activity)
        sync_run3.reload
        expect(sync_run3).to have_state(:queued)
        expect(sync_run3.sync_records.count).to eq(0)
        expect(sync_run3.sync.current_cursor_field).to eql("2022-01-02")
      end
    end

    context "when there is a new record" do
      it "creates a new sync record" do
        expect(sync_run_pending).to have_state(:pending)
        expect(subject).not_to receive(:heartbeat)
        expect(subject).not_to receive(:setup_source_client)
        expect(subject).not_to receive(:process_records)
        expect(subject).not_to receive(:process_record)
        subject.read(sync_run_pending.id, activity)
        expect(sync_run_pending).to have_state(:pending)
      end
    end

    #  TODO: test for query event

    # TODO: test for partial recovery via currrent offset
  end

  describe "#process_record" do
    let(:sync_run) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
    end
    let(:model) { create(:model) }

    context "when the primary key is blank" do
      it "does not call update_or_create_sync_record" do
        message = double("Record", data: { "TestPrimaryKey" => nil })
        expect(subject).not_to receive(:find_or_initialize_sync_record)
        subject.send(:process_record, message, sync_run, model)
      end
    end

    context "when the primary key is not blank" do
      it "calls find_or_initialize_sync_record and update_or_create_sync_record" do
        message = double("Record", data: { "TestPrimaryKey" => 1 })
        expect(subject).to receive(:find_or_initialize_sync_record)

        subject.send(:process_record, message, sync_run, model)
      end
    end
  end

  describe "#process_records" do
    # record2 and record3 are duplicate
    let(:records) { [record1, record2, record3] }

    let(:records_without_dup) { [record1, record2] }

    context "process_records records" do
      it "process_records records with duplicates" do
        skip_rows = subject.send(:process_records, records, sync_run1, sync_run1.model)

        expect(skip_rows).to eq(1)
      end
    end

    context "process_records records" do
      it "process_records records without duplicate" do
        skip_rows = subject.send(:process_records, records_without_dup, sync_run1, sync_run1.model)

        expect(skip_rows).to eq(0)
      end
    end
  end

  describe "#process_record" do
    let(:records) { [record1, record2, record3] }

    context "process_record with error" do
      it "process_record with error" do
        sync_run1.model.primary_key = nil
        sync_record = subject.send(:process_record, records, sync_run1, sync_run1.model)

        expect(sync_record).to eq(nil)
      end
    end

    describe "#update_or_create_sync_record" do
      let(:record) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                      "first_name" => "John", "Last Name" => "Doe" },
                                                              emitted_at:
                                                              DateTime.now.to_i).to_multiwoven_message
      end
      let(:record_dup) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                      "first_name" => "John", "Last Name" => "Doe" },
                                                              emitted_at:
                                                              DateTime.now.to_i).to_multiwoven_message
      end
      let(:record_update) do
        Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                      "first_name" => "John", "Last Name" => "Doe1" },
                                                              emitted_at:
                                                              DateTime.now.to_i).to_multiwoven_message
      end

      context "when there is existing sync record update the record" do
        it "updates the sync record with new status pending" do
          sync_record = subject.send(:process_record, record.record, sync_run1, sync_run1.model)
          fingerprint = ReverseEtl::Extractors::Base.new.send(:generate_fingerprint, record.record.data)
          sync_record.update!(status: "success", fingerprint:, action: "destination_insert",
                              record: record.record.data)

          fingerprint = ReverseEtl::Extractors::Base.new.send(:generate_fingerprint, record_update.record.data)
          sync_record_update = subject.send(:process_record, record_update.record, sync_run2, sync_run2.model)
          subject.send(:update_or_create_sync_record, sync_record_update, record_update.record,
                       sync_run1, fingerprint)

          updated_sync_record = SyncRecord.find(sync_record_update.id)
          expect(updated_sync_record).not_to be_nil
          expect(updated_sync_record.sync_run_id).to eq(sync_run1.id)
          expect(updated_sync_record.action).to eq("destination_update")
          expect(updated_sync_record.fingerprint).to eq(fingerprint)
          expect(updated_sync_record.status).to eq("pending")
        end
      end

      context "when there is existing sync record skip the record" do
        it "skip the record" do
          sync_record = subject.send(:process_record, record.record, sync_run1, sync_run1.model)
          fingerprint = ReverseEtl::Extractors::Base.new.send(:generate_fingerprint, record.record.data)
          sync_record.update!(status: "success", fingerprint:, action: "destination_insert",
                              record: record.record.data)

          fingerprint = ReverseEtl::Extractors::Base.new.send(:generate_fingerprint, record_dup.record.data)
          sync_record_dup = subject.send(:process_record, record_dup.record, sync_run2, sync_run2.model)
          subject.send(:update_or_create_sync_record, sync_record_dup, record_dup.record,
                       sync_run1, fingerprint)

          updated_sync_record = SyncRecord.find(sync_record_dup.id)
          expect(updated_sync_record).not_to be_nil
          expect(updated_sync_record.sync_run_id).to eq(sync_run1.id)
          expect(updated_sync_record.action).to eq("destination_insert")
          expect(updated_sync_record.fingerprint).to eq(fingerprint)
          expect(updated_sync_record.status).to eq("success")
        end
      end
    end
  end
end
