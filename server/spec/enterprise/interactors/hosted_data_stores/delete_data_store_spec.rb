# frozen_string_literal: true

require "rails_helper"

RSpec.describe HostedDataStores::DeleteDataStore, type: :interactor do
  let(:workspace) { create(:workspace) }
  let(:source_connector) { create(:connector) }
  let(:destination_connector) { create(:connector) }
  let(:hosted_data_store) { create(:hosted_data_store, workspace:, source_connector:, destination_connector:) }
  let(:hosted_data_store_table) do
    create(:hosted_data_store_table, hosted_data_store:, source_connector:, destination_connector:)
  end
  let(:params) do
    {
      template_id: "vector_store_hosted_connector"
    }
  end
  let(:mock_connection) { instance_double(PG::Connection, exec: true, close: true) }

  before do
    stub_const(
      "ENV",
      ENV.to_h.merge(
        "HOSTED_VECTOR_DB_USERNAME" => "user",
        "HOSTED_VECTOR_DB_PASSWORD" => "pass",
        "HOSTED_VECTOR_DB_HOST" => "127.0.0.1",
        "HOSTED_VECTOR_DB_PORT" => "5432",
        "HOSTED_VECTOR_DB_DATABASE" => "test_db"
      )
    )
  end

  describe "#call" do
    it "deletes a data store" do
      handler_instance = instance_double(
        HostedDataStores::Postgres::DeletePostgresHostDataStore
      )
      allow(handler_instance).to receive(:delete_data_store).and_return(true)
      allow(handler_instance).to receive(:fetch_hosted_data_store).and_return(hosted_data_store)
      allow(hosted_data_store).to receive(:destroyed?).and_return(true)
      allow(HostedDataStores::Postgres::DeletePostgresHostDataStore).to receive(:new).and_return(handler_instance)
      described_class.call(workspace:, hosted_data_store:)
      expect(hosted_data_store).to be_destroyed
    end

    it "deletes a data store if the data store is enabled" do
      hosted_data_store.update(state: "enabled")
      handler_instance = instance_double(
        HostedDataStores::Postgres::DeletePostgresHostDataStore
      )
      allow(handler_instance).to receive(:delete_data_store).and_return(true)
      allow(handler_instance).to receive(:fetch_hosted_data_store).and_return(hosted_data_store)
      allow(hosted_data_store).to receive(:destroyed?).and_return(true)
      allow(HostedDataStores::Postgres::DeletePostgresHostDataStore).to receive(:new).and_return(handler_instance)
      described_class.call(workspace:, hosted_data_store:)
      expect(hosted_data_store).to be_destroyed
    end

    it "raises an error if the data store deletion fails" do
      interactor = described_class.call(workspace:, hosted_data_store:)
      expect(interactor.destroyed?).to be_falsey
      expect(interactor.errors).to be_present
    end
  end
end
