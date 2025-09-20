# frozen_string_literal: true

require "rails_helper"

module ReverseEtl
  module Utils
    RSpec.describe Paginator do
      describe ".execute_in_batches" do
        let(:client) { double("Client") }
        context "when neither cursor_field nor current_cursor_field are present" do
          let(:source) do
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

          let(:sync) { create(:sync, destination:, source:) }
          let(:sync_run) { create(:sync_run, sync:) }

          before do
            call_count = 1
            allow(client).to receive(:read) do |_config|
              call_count += 1
              call_count < 10 ? Array.new(10, "mock_data") : []
            end
          end

          it "executes batches correctly" do
            params = {
              "page" => 1,
              "per_page" => 10,
              batch_size: 1,
              sync_config: sync.to_protocol,
              client:
            }

            expect(client).to receive(:read).exactly(9).times

            results = []
            Paginator.execute_in_batches(params) do |result|
              results << result
            end

            expect(results.size).to eq(8)
            expect(results.first.size).to eq(10)
            expect(results.last.size).to eq(10)
          end
        end
      end
    end
  end
end
