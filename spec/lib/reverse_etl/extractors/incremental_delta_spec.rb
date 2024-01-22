# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::IncrementalDelta do
  let(:source) do
    create(:connector, connector_type: "source", connector_name: "Snowflake")
  end
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, source:, destination:) }
  let(:sync_run) { create(:sync_run, sync:) }

  let(:client) { Multiwoven::Integrations::Source::Snowflake::Client.new }
  let(:record1) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1 },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end
  let(:record2) do
    Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 2 },
                                                          emitted_at: DateTime.now.to_i).to_multiwoven_message
  end

  let(:records) { [record1, record2] }

  before do
    sync.model.update(primary_key: "id")
    allow(client).to receive(:read).and_return(records)
    allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield(records, 1)
    allow(sync_run.sync.source).to receive_message_chain(:connector_client, :new).and_return(client)
  end

  describe "#read" do
    context "when there is a new record" do
      it "creates a new sync record" do
        expect { subject.read(sync_run.id) }.to change(sync_run.sync_records, :count).by(2)
      end
    end
  end

  context "when an existing record is updated" do
    it "updates the existing sync record with fingerprint change" do
      # First sync run
      subject.read(sync_run.id)
      expect(sync_run.sync_records.count).to eq(2)

      initial_sync_record = sync_run.sync_records.find_by(primary_key: record1.record.data["id"])
      expect(initial_sync_record.fingerprint).to eq(subject.send(:generate_fingerprint, record1.record.data))
      expect(initial_sync_record.action).to eq("destination_insert")

      modified_record1 = Multiwoven::Integrations::Protocol::RecordMessage.new(
        data: record1.record.data.merge({ "modified_field" => "new_value" }),
        emitted_at: DateTime.now.to_i
      ).to_multiwoven_message

      allow(ReverseEtl::Utils::BatchQuery).to receive(:execute_in_batches).and_yield([modified_record1, record2], 1)

      # Second sync run
      subject.read(sync_run.id)

      updated_sync_record = sync_run.sync_records.find_by(primary_key: record1.record.data["id"])
      expect(sync_run.sync_records.count).to eq(2)
      expect(updated_sync_record.fingerprint).not_to eq(initial_sync_record.fingerprint)
      expect(updated_sync_record.action).to eq("destination_update")
      expect(updated_sync_record.record).to eq(modified_record1.record.data)
    end
  end

  # TODO: test for partial recovery via currrent offset
end
