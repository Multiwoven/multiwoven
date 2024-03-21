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

    before do
      allow(activity).to receive(:heartbeat)
      allow(activity).to receive(:cancel_requested).and_return(false)
    end
    context "when batch support is enabled" do
      tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 2,
        failed: 0
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      it "calls process_batch_records method" do
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_batch.to_protocol, transform).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity)
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
      tracker = Multiwoven::Integrations::Protocol::TrackingMessage.new(
        success: 0,
        failed: 2
      )

      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) do
        [transformer.transform(sync_batch, sync_record_batch1), transformer.transform(sync_batch, sync_record_batch2)]
      end
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      it "calls process_batch_records method" do
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_batch.to_protocol, transform).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity)
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
        failed: 0
      )
      let(:transformer) { ReverseEtl::Transformers::UserMapping.new }
      let(:transform) { transformer.transform(sync_individual, sync_record_individual) }
      let(:multiwoven_message) { tracker.to_multiwoven_message }
      let(:client) { instance_double(sync_individual.destination.connector_client) }
      it "calls process_individual_records method" do
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_individual.to_protocol, [transform]).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity)
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

      it "calls process_individual_records method" do
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_individual.to_protocol, [transform]).and_return(multiwoven_message)
        expect(subject).to receive(:heartbeat).once.with(activity)
        expect(sync_run_individual).to have_state(:queued)
        subject.write(sync_run_individual.id, activity)
        sync_run_individual.reload
        expect(sync_run_individual).to have_state(:in_progress)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end

      it "request concurrency" do
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_individual.to_protocol, [transform]).and_return(multiwoven_message)
        expect(Parallel).to receive(:each).with(anything, in_threads: catalog.catalog["request_rate_concurrency"]).once
        subject.write(sync_run_individual.id, activity)
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

      it "sync run started to in_progress" do
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_individual.to_protocol, [transform]).and_return(multiwoven_message)
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

      it "sync run started to in_progress" do
        allow(sync_individual.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_individual.to_protocol, [transform]).and_return(multiwoven_message)
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
      let(:client) { instance_double(sync_batch.destination.connector_client) }
      it "calls process_batch_records method" do
        allow(sync_batch.destination.connector_client).to receive(:new).and_return(client)
        allow(client).to receive(:write).with(sync_batch.to_protocol, transform).and_return(multiwoven_message)
        expect(subject).not_to receive(:heartbeat)
        expect(sync_run_batch).to have_state(:queued)
        expect do
          subject.write(sync_run_batch.id, activity)
        end.to raise_error(Activities::LoaderActivity::FullRefreshFailed)

        sync_run_batch.reload
        expect(sync_run_batch).to have_state(:failed)
      end
    end
  end
end
