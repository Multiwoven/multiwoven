# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseEtl::Extractors::Base do
  let(:client) { double("Client") }
  let(:destination) { create(:connector, connector_type: "destination") }
  let!(:catalog) { create(:catalog, connector: destination) }
  let(:sync) { create(:sync, destination:) }
  let(:sync_run) { create(:sync_run, sync:) }

  describe "#read" do
    it 'raises a "Not implemented" error' do
      base_extractor = ReverseEtl::Extractors::Base.new
      expect { base_extractor.read(nil) }.to raise_error(RuntimeError, "Not implemented")
    end
  end

  describe "#batch_params" do
    it "returns correct batch parameters" do
      sync_run.update(current_offset: 100)
      sync_config = sync_run.sync.to_protocol
      sync_config.sync_run_id = sync_run.id
      expected_params = {
        offset: 100,
        limit: described_class::DEFAULT_LIMT,
        batch_size: described_class::DEFAULT_BATCH_SIZE,
        sync_config: sync_run.sync.to_protocol,
        client:
      }
      result = subject.send(:batch_params, client, sync_run)
      expect(result[:offset]).to eq(expected_params[:offset])
      expect(result[:limit]).to eq(expected_params[:limit])
      expect(result[:batch_size]).to eq(expected_params[:batch_size])
      expect(result[:sync_config]).to eq(expected_params[:sync_config])
      expect(result[:client]).to eq(expected_params[:client])
      expect(result[:sync_config]).to eq(expected_params[:sync_config])
      expect(result[:sync_config].sync_run_id).to eq(sync_run.id.to_s)
      expect(result[:sync_config].sync_id).to eq(sync_run.sync.id.to_s)
    end
  end
end
