# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Loaders::Standard do
  describe "#write" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_name: "FacebookCustomAudience", connector_type: "destination") }
    let!(:catalog) do
      create(:catalog, connector: destination,
                       catalog: {
                         "request_rate_limit" => 60,
                         "request_rate_limit_unit" => "minute",
                         "request_rate_concurrency" => 2,
                         "streams" => [{ "name" => "batch", "batch_support" => true, "batch_size" => 10,
                                         "json_schema" => {} },
                                       { "name" => "individual", "batch_support" => false, "batch_size" => 1,
                                         "json_schema" => {} }]
                       })
    end
    let!(:sync_batch) { create(:sync, stream_name: "batch", source:, destination:) }
    let!(:sync_individual) { create(:sync, stream_name: "individual", source:, destination:) }
    let!(:sync_run_batch) { create(:sync_run, sync: sync_batch, source:, destination:, status: "queued") }
    let!(:sync_run_individual) do
      create(:sync_run, sync: sync_individual, source:, destination:, status: "queued")
    end
    let!(:sync_run_started) do
      create(:sync_run, sync: sync_individual, source:, destination:, status: "started")
    end
    let!(:sync_record_batch1) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch, primary_key: "key1") }
    let!(:sync_record_batch2) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch, primary_key: "key2") }
    let!(:sync_record_individual) { create(:sync_record, sync: sync_individual, sync_run: sync_run_individual) }
    let(:activity) { instance_double("LoaderActivity") }
    let(:connector_spec) do
      Multiwoven::Integrations::Protocol::ConnectorSpecification.new(
        connector_query_type: "raw_sql",
        stream_type: "dynamic",
        connection_specification: {
          :$schema => "http://json-schema.org/draft-07/schema#",
          :title => "Snowflake",
          :type => "object",
          :stream => {}
        }
      )
    end

    let!(:sync_update) { create(:sync, stream_name: "individual", source:, destination:) }
    let!(:sync_run_dest_update) do
      create(:sync_run, sync: sync_update, source:, destination:, status: "queued")
    end
    let!(:sync_record_update) do
      create(:sync_record, sync: sync_update, sync_run: sync_run_dest_update, action: "destination_update")
    end
    before do
      allow(activity).to receive(:heartbeat).and_return(activity)
      allow(activity).to receive(:cancel_requested).and_return(false)
    end
    context "when batch support is enabled" do
      let(:rec_key_uuid) { "batch-key-uuid" }
      let(:uuid1) { "batch-record-uuid-1" }
      let(:uuid2) { "batch-record-uuid-2" }
      let(:tracker) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: 2,
          failed: 0,
          logs: [
            Multiwoven::Integrations::Protocol::LogMessage.new(level: "info", message: "ok",
                                                               record_identifier: uuid1),
            Multiwoven::Integrations::Protocol::LogMessage.new(level: "info", message: "ok",
                                                               record_identifier: uuid2)
          ]
        )
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { double("client") }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        allow(SecureRandom).to receive(:uuid).and_return(rec_key_uuid, uuid1, uuid2)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        expect(sync_run_batch).to have_state(:queued)
        subject.write(sync_run_batch.id, activity)
        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:in_progress)
        expect(sync_run_batch.sync_records.count).to eq(2)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("success")
        end
      end
    end

    context "when batch support is enabled and all failed" do
      let(:rec_key_uuid) { "batch-key-uuid-failed" }
      let(:uuid1) { "batch-failed-uuid-1" }
      let(:uuid2) { "batch-failed-uuid-2" }
      let(:error_message) { { "error" => "constraint violation" }.to_json }
      let(:tracker) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: 0,
          failed: 2,
          logs: [
            Multiwoven::Integrations::Protocol::LogMessage.new(level: "error", message: error_message,
                                                               record_identifier: uuid1),
            Multiwoven::Integrations::Protocol::LogMessage.new(level: "error", message: error_message,
                                                               record_identifier: uuid2)
          ]
        )
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { double("client") }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        allow(SecureRandom).to receive(:uuid).and_return(rec_key_uuid, uuid1, uuid2)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        subject.write(sync_run_batch.id, activity)
        expect(sync_run_batch).to have_state(:queued)
        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:in_progress)
        expect(sync_run_batch.sync_records.count).to eq(2)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end
    end

    context "when batch support is disabled" do
      tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 1,
        failed: 0,
        logs: [
          Multiwoven::Integrations::Protocol::LogMessage.new(
            name: self.class.name,
            level: "info",
            message: { request: "Sample req", response: "Sample req", level: "info" }.to_json
          )
        ]
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_individual_records method" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(multiwoven_message)
        expect(subject).to receive(:update_sync_record_logs_and_status)
          .once.with(multiwoven_message, sync_run_individual.sync_records.first)
          .and_call_original
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:in_progress)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("success")
        end
      end
    end
    context "when batch support is disabled and failed" do
      tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 1
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        allow(activity).to receive(:heartbeat).and_return(activity)
      end

      it "calls process_individual_records throw standard error" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_raise(StandardError.new("write error"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
      end

      it "calls process_individual_records method" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:in_progress)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end

      it "calls process_individual_records method for destination update" do
        sync_config = sync_update.to_protocol
        sync_config.sync_run_id = sync_run_dest_update.id.to_s

        allow(sync_update.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_update").and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_dest_update)
        expect(sync_run_dest_update).to have_state(:queued)
        subject.write(sync_run_dest_update.id, activity)
        sync_run_dest_update.reload
        expect(sync_run_dest_update).to have_state(:in_progress)
        expect(sync_run_dest_update.sync_records.count).to eq(1)
        sync_run_dest_update.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end

      it "request concurrency" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(multiwoven_message)
        expect(Parallel).to receive(:each).with(anything, in_threads: catalog.catalog["request_rate_concurrency"]).once
        subject.write(sync_run_individual.id, activity)
      end

      it "handles heartbeat timeout and updates sync run state" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(activity).to receive(:cancel_requested).and_return(true)
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(multiwoven_message)
        expect(Parallel).to receive(:each).with(anything, in_threads: catalog.catalog["request_rate_concurrency"]).once
        expect { subject.write(sync_run_individual.id, activity) }
          .to raise_error(StandardError, "Cancel activity request received")
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:failed)
      end
    end

    context "when skip loading when status is corrupted" do
      tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 1
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "sync run started to in_progress" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_started.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform]).and_return(multiwoven_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_started).to have_state(:started)
        subject.write(sync_run_started.id, activity)
        sync_run_started.reload
        expect(sync_run_started).to have_state(:started)
      end
    end

    context "Full Refresh: Clearing Records Failure for Sync processing individual" do
      control = Multiwoven::Integrations::Protocol::ControlMessage.new(
        type: "full_refresh",
        emitted_at: Time.zone.now.to_i,
        status: Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"],
        meta: { detail: "failed" }
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:multiwoven_message) { control.to_multiwoven_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "sync run started to in_progress" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_return(multiwoven_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_individual).to have_state(:queued)
        expect do
          subject.write(sync_run_individual.id, activity)
        end.to raise_error(Activities::LoaderActivity::FullRefreshFailed)

        sync_run_individual.reload

        expect(sync_run_individual).to have_state(:failed)
      end
    end

    context "Full Refresh: Clearing Records Failure for Sync processing for batch" do
      control = Multiwoven::Integrations::Protocol::ControlMessage.new(
        type: "full_refresh",
        emitted_at: Time.zone.now.to_i,
        status: Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"],
        meta: { detail: "failed" }
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:multiwoven_message) { control.to_multiwoven_message }
      let(:client) { double("client") }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end
      it "calls process_batch_records method" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_return(multiwoven_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_batch).to have_state(:queued)
        expect do
          subject.write(sync_run_batch.id, activity)
        end.to raise_error(Activities::LoaderActivity::FullRefreshFailed)

        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:failed)
      end
    end

<<<<<<< HEAD
=======
    context "when individual record processing hits StandardError" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "marks sync_record as failed" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_config, [transform],
                                              "destination_insert").and_raise(StandardError.new("write error"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        subject.write(sync_run_individual.id, activity)
        sync_record_individual.reload
        expect(sync_record_individual.status).to eq("failed")
        expect(sync_record_individual.logs).to eq({ "error" => "write error" })
      end
    end

    context "when individual record processing hits ActiveRecord::RecordNotUnique" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "marks sync_record as failed with unique violation" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write)
          .with(sync_config, [transform], "destination_insert")
          .and_raise(ActiveRecord::RecordNotUnique.new("duplicate key"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_individual)
        subject.write(sync_run_individual.id, activity)
        sync_record_individual.reload
        expect(sync_record_individual.status).to eq("failed")
      end
    end

    context "when individual record processing creates per-thread clients" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      let(:tracker) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(success: 1, failed: 0)
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "calls connector_client.new per thread, not shared" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        expect(sync_individual.destination.connector_client).to receive(:new).at_least(:once).and_return(client)
        allow(client).to receive(:write).and_return(multiwoven_message)
        subject.write(sync_run_individual.id, activity)
      end
    end

    context "when individual record processing cleans up client" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:client) { double("client", connector_spec:, close: nil) }

      it "closes client even when error occurs" do
        sync_config = sync_individual.to_protocol
        sync_config.sync_run_id = sync_run_individual.id.to_s

        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_raise(StandardError.new("boom"))
        expect(client).to receive(:close).at_least(:once)
        subject.write(sync_run_individual.id, activity)
      end
    end

    context "when batch processing hits StandardError" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:client) { double("client") }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "marks all batch records as failed" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s

        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_raise(StandardError.new("batch error"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        subject.write(sync_run_batch.id, activity)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end
    end

    context "when batch processing hits ActiveRecord::RecordNotUnique" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:client) { double("client") }
      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
      end

      it "marks all batch records as failed" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s

        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write)
          .and_raise(ActiveRecord::RecordNotUnique.new("duplicate"))
        expect(subject).to receive(:heartbeat).once.with(activity, sync_run_batch)
        subject.write(sync_run_batch.id, activity)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end
    end

    context "when batch processing cleans up client" do
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:client) { double("client", connector_spec:, close: nil) }

      it "closes client even when error occurs" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s

        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_raise(StandardError.new("boom"))
        expect(client).to receive(:close).once
        subject.write(sync_run_batch.id, activity)
      end
    end

    context "when batch support is enabled and records span multiple batch groups" do
      let(:client) { double("client") }

      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        # 2 records already exist (sync_record_batch1, sync_record_batch2).
        # To get 2 each_slice groups we need > THREAD_COUNT batches (batch_size=10).
        # Formula: THREAD_COUNT * 10 - 2 + 1 extra records → THREAD_COUNT+1 batches → 2 groups.
        # Works regardless of SYNC_LOADER_THREAD_POOL_SIZE env value.
        thread_count = described_class::THREAD_COUNT
        extra_records = (thread_count * 10) - 2 + 1
        extra_records.times do |i|
          create(:sync_record, sync: sync_batch, sync_run: sync_run_batch, primary_key: "extra_#{i}")
        end
        # Return a TrackingMessage with info-level log entries for every record in the batch so
        # all records are classified as successful under the new per-log classification logic.
        allow(client).to receive(:write) do |_config, records, _action, identifier_key|
          logs = records.map do |r|
            Multiwoven::Integrations::Protocol::LogMessage.new(
              level: "info",
              message: "ok",
              record_identifier: r[identifier_key]
            )
          end
          Multiwoven::Integrations::Protocol::TrackingMessage.new(
            success: records.size, failed: 0, logs:
          ).to_multiwoven_message
        end
      end

      it "calls heartbeat once per batch group, not once total" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)

        expect(subject).to receive(:heartbeat).twice.with(activity, sync_run_batch)
        subject.write(sync_run_batch.id, activity)
      end

      it "calls update_sync_records_status once per batch group" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)

        expect(subject).to receive(:update_sync_records_logs_and_status).twice.and_call_original
        subject.write(sync_run_batch.id, activity)
      end

      it "marks all records across all groups as success" do
        sync_config = sync_batch.to_protocol
        sync_config.sync_run_id = sync_run_batch.id.to_s
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)

        subject.write(sync_run_batch.id, activity)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("success")
        end
      end
    end

    describe "#build_failed_sync_records_from_report" do
      let(:uuid1) { "test-uuid-1" }
      let(:uuid2) { "test-uuid-2" }
      let(:sync_record_identifier_to_id) { { uuid1 => sync_record_batch1.id, uuid2 => sync_record_batch2.id } }
      let(:error_log_message) { { request: "fallback_insert", response: "some error", level: "error" }.to_json }
      let(:info_log_message) { { request: "fallback_insert", response: "ok", level: "info" }.to_json }

      context "when a log has level 'error' for a matched identifier" do
        let(:log) do
          instance_double(Multiwoven::Integrations::Protocol::LogMessage,
                          record_identifier: uuid1, message: error_log_message, level: "error")
        end
        let(:report) { double("Report", tracking: double("Tracking", logs: [log])) }

        it "returns the record in failed_records with parsed logs, and unmatched record is absent" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(failed.size).to eq(1)
          expect(failed.first[:id]).to eq(sync_record_batch1.id)
          expect(failed.first[:status]).to eq("failed")
          expect(failed.first[:logs]).to eq(JSON.parse(error_log_message))
          expect(successful).to be_empty
        end
      end

      context "when a log has level 'info' for a matched identifier" do
        let(:log) do
          instance_double(Multiwoven::Integrations::Protocol::LogMessage,
                          record_identifier: uuid1, message: info_log_message, level: "info")
        end
        let(:report) { double("Report", tracking: double("Tracking", logs: [log])) }

        it "returns the record in successful_records with nil logs" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(successful.size).to eq(1)
          expect(successful.first[:id]).to eq(sync_record_batch1.id)
          expect(successful.first[:status]).to eq("success")
          expect(failed).to be_empty
        end
      end

      context "when logs is empty" do
        let(:report) { double("Report", tracking: double("Tracking", logs: [])) }

        it "returns two empty arrays" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(successful).to be_empty
          expect(failed).to be_empty
        end
      end

      context "when logs is nil" do
        let(:report) { double("Report", tracking: double("Tracking", logs: nil)) }

        it "returns two empty arrays" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(successful).to be_empty
          expect(failed).to be_empty
        end
      end

      context "when a log record_identifier is not in the map" do
        let(:log) do
          instance_double(Multiwoven::Integrations::Protocol::LogMessage,
                          record_identifier: "unknown-uuid", message: error_log_message, level: "error")
        end
        let(:report) { double("Report", tracking: double("Tracking", logs: [log])) }

        it "skips the unrecognized identifier and returns empty arrays" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(successful).to be_empty
          expect(failed).to be_empty
        end
      end

      context "when a log message is not valid JSON" do
        let(:bad_message) { "not valid json {{" }
        let(:log) do
          instance_double(Multiwoven::Integrations::Protocol::LogMessage,
                          record_identifier: uuid1, message: bad_message, level: "error")
        end
        let(:report) { double("Report", tracking: double("Tracking", logs: [log])) }

        it "falls back to wrapping the raw message in an error hash and places the record in failed_records" do
          successful, failed = subject.send(:build_failed_sync_records_from_report,
                                            sync_record_identifier_to_id, report, "ignored_key")
          expect(failed.size).to eq(1)
          expect(failed.first[:logs]).to eq({ "error" => bad_message })
          expect(successful).to be_empty
        end
      end
    end

    describe "#build_transformed_batch" do
      let(:sync_records) { [sync_record_batch1, sync_record_batch2] }

      it "returns a three-element array of [transformed_records, identifier_map, identifier_key]" do
        result = subject.send(:build_transformed_batch, sync_batch, sync_records)
        expect(result.size).to eq(3)
        transformed_records, identifier_map, identifier_key = result
        expect(transformed_records).to be_an(Array)
        expect(identifier_map).to be_a(Hash)
        expect(identifier_key).to be_a(String)
      end

      it "embeds a unique identifier in each transformed record under identifier_key" do
        transformed_records, _identifier_map, identifier_key = subject.send(:build_transformed_batch, sync_batch,
                                                                            sync_records)
        identifiers = transformed_records.map { |r| r[identifier_key] }
        expect(identifiers.size).to eq(2)
        expect(identifiers.uniq.size).to eq(2)
        identifiers.each { |id| expect(id).to be_present }
      end

      it "maps each record's identifier back to the original sync_record id" do
        transformed_records, identifier_map, identifier_key = subject.send(:build_transformed_batch, sync_batch,
                                                                           sync_records)
        mapped_ids = transformed_records.map { |r| identifier_map[r[identifier_key]] }
        expect(mapped_ids).to match_array([sync_record_batch1.id, sync_record_batch2.id])
      end
    end

    describe "#build_failed_sync_records_from_sync_records" do
      let(:sync_records) { [{ "id" => sync_record_batch1.id }, { "id" => sync_record_batch2.id }] }
      let(:valid_json_message) { { "error" => "duplicate key" }.to_json }

      it "builds failed records with parsed logs for each sync record" do
        results = subject.send(:build_failed_sync_records_from_sync_records, sync_records, valid_json_message)
        expect(results.size).to eq(2)
        results.each do |r|
          expect(r[:status]).to eq("failed")
          expect(r[:logs]).to eq({ "error" => "duplicate key" })
        end
        expect(results.map { |r| r[:id] }).to match_array([sync_record_batch1.id, sync_record_batch2.id])
      end
    end

    describe "#update_sync_records_logs_and_status" do
      it "marks successful records via upsert_all" do
        successful = [
          { id: sync_record_batch1.id, status: "success", logs: nil },
          { id: sync_record_batch2.id, status: "success", logs: nil }
        ]
        subject.send(:update_sync_records_logs_and_status, sync_run_batch, successful, [])
        sync_run_batch.sync_records.reload.each do |r|
          expect(r.status).to eq("success")
        end
      end

      it "marks failed records with logs via upsert_all" do
        log_data = { "request" => "fallback_insert", "response" => "error", "level" => "error" }
        failed = [
          { id: sync_record_batch1.id, status: "failed", logs: log_data },
          { id: sync_record_batch2.id, status: "failed", logs: nil }
        ]
        subject.send(:update_sync_records_logs_and_status, sync_run_batch, [], failed)
        sync_record_batch1.reload
        expect(sync_record_batch1.status).to eq("failed")
        expect(sync_record_batch1.logs).to eq(log_data)
        sync_record_batch2.reload
        expect(sync_record_batch2.status).to eq("failed")
        expect(sync_record_batch2.logs).to be_nil
      end

      it "returns early without touching the database when both lists are empty" do
        expect(sync_run_batch.sync_records).not_to receive(:upsert_all)
        subject.send(:update_sync_records_logs_and_status, sync_run_batch, [], [])
      end
    end

    context "when batch support is enabled and fails with logs" do
      let(:uuid1) { "fails-with-logs-uuid-1" }
      let(:uuid2) { "fails-with-logs-uuid-2" }
      let(:log_message) { { request: "fallback_insert", response: "constraint error", level: "error" }.to_json }
      let(:tracker) do
        Multiwoven::Integrations::Protocol::TrackingMessage.new(
          success: 0,
          failed: 2,
          logs: [
            Multiwoven::Integrations::Protocol::LogMessage.new(
              level: "error",
              message: log_message,
              record_identifier: uuid1
            ),
            Multiwoven::Integrations::Protocol::LogMessage.new(
              level: "error",
              message: log_message,
              record_identifier: uuid2
            )
          ]
        )
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { double("client") }

      before do
        allow(client).to receive(:connector_spec).and_return(connector_spec)
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).and_return(multiwoven_message)
        allow(SecureRandom).to receive(:uuid).and_return("batch-key-uuid", uuid1, uuid2)
      end

      it "stores logs on failed sync records" do
        subject.write(sync_run_batch.id, activity)
        sync_run_batch.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
          expect(sync_record.logs).to eq(JSON.parse(log_message))
        end
      end
    end

>>>>>>> e4bf26352 (fix(CE): implemented record_identifier mapper for batch support (#1886))
    context "when the report has tracking logs with a message" do
      let(:log_message) { '{"request":"Sample log message"}' }
      let(:report) do
        double("Report", tracking: double("Tracking", logs: [double("Log", message: log_message)]))
      end

      it "returns the log message" do
        expected_result = { "request" => "Sample log message" }
        expect(subject.send(:get_sync_records_logs, report)).to eq(expected_result)
      end
    end

    context "when the report has tracking logs without a message" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: [double("Log", message: nil)]))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report has tracking logs but no logs present" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: []))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report does not respond to logs" do
      let(:report) { double("Report", tracking: double("Tracking")) }

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end

    context "when the report has no tracking" do
      let(:report) do
        double("Report", tracking: double("Tracking", logs: nil))
      end

      it "returns nil" do
        expect(subject.send(:get_sync_records_logs, report)).to be_nil
      end
    end
  end
end
