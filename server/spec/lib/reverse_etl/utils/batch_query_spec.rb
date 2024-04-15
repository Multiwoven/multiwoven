# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils
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
          let(:source) { create(:connector, connector_type: "source") }
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
                                                                          "timestamp" => "2022-01-01" },
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

            results = []
            BatchQuery.execute_in_batches(params) do |result, current_offset, last_cursor_field_value|
              expect(result.first).to be_an_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
              expect(current_offset).to eq(100)
              expect(last_cursor_field_value).to eq("2022-01-01")
              results << result
            end
          end
        end
      end
    end
  end
end
