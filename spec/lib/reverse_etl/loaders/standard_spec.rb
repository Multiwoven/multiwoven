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
                         "streams" => [{ "name" => "batch", "batch_support" => true, "batch_size" => 10,
                                         "json_schema" => {} },
                                       { "name" => "individual", "batch_support" => false, "batch_size" => 1,
                                         "json_schema" => {} }]
                       })
    end
    let!(:sync_batch) { create(:sync, stream_name: "batch", source:, destination:) }
    let!(:sync_individual) { create(:sync, stream_name: "individual", source:, destination:) }
    let!(:sync_run_batch) { create(:sync_run, sync: sync_batch) }
    let!(:sync_run_individual) { create(:sync_run, sync: sync_individual) }
    let!(:sync_record_batch1) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch) }
    let!(:sync_record_batch2) { create(:sync_record, sync: sync_batch, sync_run: sync_run_batch) }
    let!(:sync_record_individual) { create(:sync_record, sync: sync_individual, sync_run: sync_run_individual) }

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
        subject.write(sync_run_batch.id)
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
        subject.write(sync_run_batch.id)
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
        subject.write(sync_run_individual.id)
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
        subject.write(sync_run_individual.id)
        expect(sync_run_individual.sync_records.count).to eq(1)
        sync_run_individual.sync_records.reload.each do |sync_record|
          expect(sync_record.status).to eq("failed")
        end
      end
    end
  end
end
