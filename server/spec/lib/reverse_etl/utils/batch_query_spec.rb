# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils # rubocop:disable Metrics/ModuleLength
    RSpec.describe BatchQuery do
      describe ".execute_in_batches" do
        let(:client) { double("Client") }
        context "when neither cursor_field nor current_cursor_field are present" do
          let(:destination) { create(:connector, connector_type: "destination") }
          let!(:catalog) { create(:catalog, connector: destination) }

          let(:sync) { create(:sync, destination:) }

          before do
            call_count = 0
            allow(client).to receive(:read) do |_config|
              call_count += 1
              call_count < 10 ? Array.new(100, "mock_data") : []
            end
          end

          it "executes batches correctly" do
            params = {
              offset: 0,
              limit: 100,
              batch_size: 100,
              sync_config: sync.to_protocol,
              client:
            }

            expect(client).to receive(:read).exactly(10).times

            results = []
            BatchQuery.execute_in_batches(params) do |result|
              results << result
            end

            expect(results.size).to eq(9)
            expect(results.first.size).to eq(100)
            expect(results.last.size).to eq(100)
          end
        end
        context "when both cursor_field is present" do
          let(:existing_query) { "SELECT * FROM table" }
          let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
          let(:destination) { create(:connector, connector_type: "destination") }
          let!(:catalog) { create(:catalog, connector: destination) }
          let(:model) { create(:model, connector: source, query: existing_query) }
          let(:sync) do
            create(:sync, model:, source:, destination:, cursor_field: "timestamp",
                          current_cursor_field: "2022-01-01")
          end
          let(:record) do
            Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                          "first_name" => "John", "Last Name" => "Doe",
                                                                          "timestamp" => "2022-01-02" },
                                                                  emitted_at: DateTime.now.to_i).to_multiwoven_message
          end

          it "executes batches and call CursorQueryBuilder" do
            params = {
              offset: 0,
              limit: 100,
              batch_size: 100,
              sync_config: sync.to_protocol,
              client:
            }
            allow(client).to receive(:read).and_return(*Array.new(1, [record]), [])
            expect(CursorQueryBuilder).to receive(:build_cursor_query).with(sync.to_protocol,
                                                                            "2022-01-01")
                                                                      .and_call_original.once
            expect(CursorQueryBuilder).to receive(:build_cursor_query).with(sync.to_protocol,
                                                                            "2022-01-02")
                                                                      .and_call_original.once
            results = []
            BatchQuery.execute_in_batches(params) do |result, current_offset, last_cursor_field_value|
              expect(result.first).to be_an_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
              expect(current_offset).to eq(100)
              expect(last_cursor_field_value).to eq("2022-01-02")
              results << result
            end
          end
        end
      end

      describe ".extract_last_cursor_field_value" do
        let(:sync_config) { instance_double(Multiwoven::Integrations::Protocol::SyncConfig, cursor_field: "timestamp") }

        context "when result is empty" do
          it "returns nil" do
            result = []
            expect(described_class.extract_last_cursor_field_value(result, sync_config)).to be_nil
          end
        end

        context "when result is not empty" do
          let(:record1) do
            Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                          "first_name" => "John", "Last Name" => "Doe",
                                                                          "timestamp" => "2022-01-01" },
                                                                  emitted_at: DateTime.now.to_i).to_multiwoven_message
          end
          let(:record2) do
            Multiwoven::Integrations::Protocol::RecordMessage.new(data: { "id" => 1, "email" => "test1@mail.com",
                                                                          "first_name" => "John", "Last Name" => "Doe",
                                                                          "timestamp" => "2022-01-02" },
                                                                  emitted_at: DateTime.now.to_i).to_multiwoven_message
          end
          let(:result) { [record1, record2] }

          it "returns the value of the last record's cursor field" do
            expect(described_class.extract_last_cursor_field_value(result, sync_config)).to eq("2022-01-02")
          end
        end

        context "when sync_config has no cursor field" do
          let(:sync_config) { instance_double(Multiwoven::Integrations::Protocol::SyncConfig, cursor_field: nil) }
          let(:result) do
            [instance_double(Multiwoven::Integrations::Protocol::RecordMessage, data: { "timestamp" => "2022-01-01" })]
          end

          it "returns nil" do
            expect(described_class.extract_last_cursor_field_value(result, sync_config)).to be_nil
          end
        end
      end

      describe ".build_cursor_sync_config" do
        let(:existing_query) { "SELECT * FROM table" }
        let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
        let(:destination) { create(:connector, connector_type: "destination") }
        let!(:catalog) { create(:catalog, connector: destination) }
        let(:model) { create(:model, connector: source, query: existing_query) }
        let(:sync) do
          create(:sync, model:, source:, destination:, cursor_field: "timestamp",
                        current_cursor_field: "2022-01-01")
        end

        let(:new_query) { "SELECT * FROM table WHERE timestamp >= '2022-01-01'" }
        let(:sync_config) { sync.to_protocol }

        it "builds a new SyncConfig with modified query and other attributes" do
          modified_sync_config = described_class.build_cursor_sync_config(sync_config, new_query)

          expect(modified_sync_config).to be_a(Multiwoven::Integrations::Protocol::SyncConfig)
          expect(modified_sync_config.model.name).to eq(sync_config.model.name)
          expect(modified_sync_config.model.query).to eq("SELECT * FROM table WHERE timestamp >= '2022-01-01'")
          expect(modified_sync_config.model.query_type).to eq("raw_sql")
          expect(modified_sync_config.model.primary_key).to eq("TestPrimaryKey")
          expect(modified_sync_config.source).to eq(source.to_protocol)
          expect(modified_sync_config.destination).to eq(destination.to_protocol)
          expect(modified_sync_config.stream).to eq(sync_config.stream)
          expect(modified_sync_config.sync_mode).to eq(sync_config.sync_mode)
          expect(modified_sync_config.destination_sync_mode).to eq(sync_config.destination_sync_mode)
          expect(modified_sync_config.cursor_field).to eq(sync_config.cursor_field)
          expect(modified_sync_config.current_cursor_field).to eq(sync_config.current_cursor_field)
          expect(modified_sync_config.limit).to eq(sync_config.limit)
          expect(modified_sync_config.offset).to eq(0)
        end
      end

      describe ".build_new_model" do
        let(:existing_model) { instance_double(Model, name: "ExistingModel", query_type: "raw_sql", primary_key: "id") }
        let(:new_query) { "SELECT * FROM table WHERE timestamp >= '2022-01-01'" }

        it "builds a new Model with modified query and other attributes" do
          new_model = described_class.build_new_model(existing_model, new_query)

          expect(new_model).to be_a(Model)
          expect(new_model.name).to eq("ExistingModel")
          expect(new_model.query).to eq("SELECT * FROM table WHERE timestamp >= '2022-01-01'")
          expect(new_model.query_type).to eq("raw_sql")
          expect(new_model.primary_key).to eq("id")
        end
      end
    end
  end
end
