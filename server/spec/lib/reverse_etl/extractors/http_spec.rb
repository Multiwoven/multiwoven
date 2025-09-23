# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::Http do
  let(:source) do
    create(
      :connector,
      connector_type: "source",
      connector_name: "Http",
      configuration: {
        "increment_type" => "Offset",
        "page_start" => "0",
        "page_size" => "10000",
        "offset_param" => "offset",
        "limit_param" => "limit"
      }
    )
  end
  let(:source2) do
    create(
      :connector,
      connector_type: "source",
      connector_name: "Http",
      configuration: {
        "increment_type" => "Page",
        "page_start" => "1",
        "page_size" => "10",
        "offset_param" => "page",
        "limit_param" => "per_page"
      }
    )
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync2) { create(:sync, source: source2, destination:) }
  let(:sync_run1) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run2) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run3) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end
  let(:sync_run4) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "started")
  end

  let(:sync_run5) do
    create(
      :sync_run,
      sync: sync2,
      workspace: sync.workspace,
      source:,
      destination:,
      model: sync.model,
      status: "started"
    )
  end
  let(:sync_run6) do
    create(
      :sync_run,
      sync: sync2,
      workspace: sync.workspace,
      source:,
      destination:,
      model: sync.model,
      status: "started"
    )
  end
  let(:sync_run7) do
    create(
      :sync_run,
      sync: sync2,
      workspace: sync.workspace,
      source:,
      destination:,
      model: sync.model,
      status: "started"
    )
  end

  let(:sync_run_pending) do
    create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "pending")
  end
  let(:activity) { instance_double("ExtractorActivity") }

  let(:client) { Multiwoven::Integrations::Source::Http::Client.new }
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
    allow(activity).to receive(:heartbeat).and_return(activity)
    allow(activity).to receive(:cancel_requested).and_return(false)
  end

  describe "#read with offset increment strategy" do
    context "when there is a new record" do
      it "creates a new sync record" do
        expect(subject).to receive(:heartbeat).exactly(:once)
        expect { subject.read(sync_run1.id, activity) }.to change(sync_run1.sync_records, :count).by(2)
      end
    end

    context "when an existing record is updated" do
      it "updates the existing sync record with fingerprint change" do
        # First sync run
        expect(sync_run1).to have_state(:started)
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
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run2, nil)
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
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run3, "2022-01-01")
        subject.read(sync_run3.id, activity)
        sync_run3.reload
        expect(sync_run3).to have_state(:queued)
        expect(sync_run3.sync_records.count).to eq(0)
        expect(sync_run3.sync.current_cursor_field).to eql("2022-01-02")
      end

      it "handles heartbeat timeout and updates sync run state" do
        expect(sync_run1).to have_state(:started)
        allow(activity).to receive(:cancel_requested).and_return(true)
        allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches)
          .and_yield([record2, record3], 1, "2022-01-06")
        expect { subject.read(sync_run1.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(0)
        expect(sync_run1.sync.current_cursor_field).to eq(nil)
        expect(sync_run1).to have_state(:failed)
      end

      it "handles heartbeat timeout cursor field" do
        expect(sync_run1).to have_state(:started)
        sync_run1.sync.update(current_cursor_field: "2022-05-01")
        allow(activity).to receive(:cancel_requested).and_return(true)
        expect { subject.read(sync_run1.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run1.reload
        expect(sync_run1.sync_records.count).to eq(0)
        expect(sync_run1.sync.current_cursor_field).to eq("2022-05-01")
        expect(sync_run1).to have_state(:failed)
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
  end

  describe "#read with page increment strategy" do
    before do
      sync2.model.update(primary_key: "id")
      allow(client).to receive(:read).and_return(records)
      allow(ReverseEtl::Utils::Paginator).to receive(:execute_in_batches).and_yield(records, 1)
      allow(sync_run5.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
      allow(activity).to receive(:heartbeat).and_return(activity)
      allow(activity).to receive(:cancel_requested).and_return(false)
    end

    context "when there is a new record" do
      it "creates a new sync record" do
        expect(subject).to receive(:heartbeat).exactly(:once)
        expect { subject.read(sync_run5.id, activity) }.to change(sync_run5.sync_records, :count).by(2)
      end
    end

    context "when an existing record is updated" do
      it "updates the existing sync record with fingerprint change" do
        # First sync run
        expect(sync_run5).to have_state(:started)
        subject.read(sync_run5.id, activity)
        sync_run5.reload
        expect(sync_run5.sync_records.count).to eq(2)
        expect(sync_run5).to have_state(:queued)

        initial_sync_record = sync_run5.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(initial_sync_record.fingerprint).to eq(subject.send(:generate_fingerprint, record1.record.data))
        expect(initial_sync_record.action).to eq("destination_insert")

        initial_sync_record_second = sync_run5.sync_records.find_by(primary_key: record2.record.data["id"])
        expect(initial_sync_record_second.fingerprint).to eq(subject.send(:generate_fingerprint, record2.record.data))
        expect(initial_sync_record_second.action).to eq("destination_insert")

        modified_record1 = Multiwoven::Integrations::Protocol::RecordMessage.new(
          data: record1.record.data.merge({ "modified_field" => "new_value" }),
          emitted_at: DateTime.now.to_i
        ).to_multiwoven_message

        allow(ReverseEtl::Utils::Paginator).to receive(:execute_in_batches).and_yield([modified_record1, record2], 1)

        # Second sync run
        expect(sync_run6).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run6, nil)
        subject.read(sync_run6.id, activity)
        sync_run6.reload
        expect(sync_run6).to have_state(:queued)

        updated_sync_record = sync_run6.sync_records.find_by(primary_key: record1.record.data["id"])
        expect(sync_run6.sync_records.count).to eq(1)
        expect(updated_sync_record.fingerprint).not_to eq(initial_sync_record.fingerprint)
        expect(updated_sync_record.action).to eq("destination_update")
        expect(updated_sync_record.record).to eq(modified_record1.record.data)

        allow(ReverseEtl::Utils::Paginator).to receive(:execute_in_batches).and_yield([record2, record3], 1)

        # Third sync run with same record
        expect(sync_run7).to have_state(:started)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run7, nil)
        subject.read(sync_run7.id, activity)
        sync_run7.reload
        expect(sync_run7).to have_state(:queued)
        expect(sync_run7.sync_records.count).to eq(0)
      end

      it "handles heartbeat timeout and updates sync run state" do
        expect(sync_run5).to have_state(:started)
        allow(activity).to receive(:cancel_requested).and_return(true)
        allow(ReverseEtl::Utils::Paginator).to receive(:execute_in_batches)
          .and_yield([record2, record3], 1)
        expect { subject.read(sync_run5.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run5.reload
        expect(sync_run5.sync_records.count).to eq(0)
        expect(sync_run5).to have_state(:failed)
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
  end
end
