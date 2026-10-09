# frozen_string_literal: true

require "rails_helper"

RSpec.describe Syncs::CreateSync do
  let(:workspace) { create(:workspace) }
  let(:source) { create(:connector, workspace:, connector_type: "source") }
  let(:destination) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector: source) }
  let(:sync) do
    build(:sync, workspace:, source:, destination:, model:, cursor_field: "timestamp",
                 current_cursor_field: "2022-01-01")
  end
  let(:in_host_source) { create(:connector, workspace:, connector_type: "source", in_host: true) }
  let(:in_host_destination) { create(:connector, workspace:, connector_type: "destination", in_host: true) }
  let!(:hosted_data_store) do
    create(
      :hosted_data_store,
      workspace:,
      source_connector: in_host_source,
      destination_connector: in_host_destination
    )
  end
  let!(:hosted_data_store_table) do
    create(
      :hosted_data_store_table,
      hosted_data_store:,
      source_connector: in_host_source,
      destination_connector: in_host_destination,
      name: "profile",
      sync_enabled: :disabled
    )
  end
  let(:in_host_model) { create(:model, workspace:, connector: in_host_source) }
  let(:in_host_sync1) do
    build(:sync, workspace:, source: in_host_source, destination:, model: in_host_model, cursor_field: "timestamp",
                 current_cursor_field: "2022-01-01", stream_name: "profile")
  end
  let(:in_host_sync2) do
    build(:sync, workspace:, source:, destination: in_host_destination, model: in_host_model, cursor_field: "timestamp",
                 current_cursor_field: "2022-01-01", stream_name: "profile")
  end

  before do
    create(:catalog, connector: source)
    create(:catalog, connector: destination)
    create(:catalog, connector: in_host_source)
    create(:catalog, connector: in_host_destination)
  end

  context "with valid params" do
    it "creates a sync" do
      result = described_class.call(
        workspace:,
        sync_params: sync.attributes.except("id", "created_at", "updated_at").with_indifferent_access
      )
      expect(result.success?).to eq(true)
      expect(result.sync.persisted?).to eql(true)
      expect(result.sync.source_id).to eql(source.id)
      expect(result.sync.destination_id).to eql(destination.id)
      expect(result.sync.model_id).to eql(model.id)
      expect(result.sync.cursor_field).to eql(sync.cursor_field)
      expect(result.sync.current_cursor_field).to eql(sync.current_cursor_field)
    end
  end

  context "with in_host source connector" do
    it "creates a sync" do
      in_host_model.query = "SELECT * FROM schema.profile"
      in_host_model.save!
      result = described_class.call(
        workspace:,
        sync_params: in_host_sync1.attributes.except("id", "created_at", "updated_at").with_indifferent_access
      )
      expect(result.success?).to eq(true)
      hosted_data_store_table.reload
      expect(hosted_data_store_table.sync_enabled).to eq("enabled")
    end
  end

  context "with in_host destination connector" do
    it "creates a sync" do
      in_host_model.query = "SELECT * FROM schema.profile"
      in_host_model.save!
      result = described_class.call(
        workspace:,
        sync_params: in_host_sync2.attributes.except("id", "created_at", "updated_at").with_indifferent_access
      )
      expect(result.success?).to eq(true)
      hosted_data_store_table.reload
      expect(hosted_data_store_table.sync_enabled).to eq("enabled")
    end
  end

  context "with invalid params" do
    let(:sync_params) do
      sync.attributes.except("id", "created_at", "destination_id")
    end

    it "fails to create sync" do
      result = described_class.call(workspace:, sync_params: sync_params.with_indifferent_access)
      expect(result.failure?).to eq(true)
      expect(result.sync.persisted?).to eql(false)
    end
  end
end
