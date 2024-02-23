# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe DestinationConnector do
      let(:sync_config) { instance_double("SyncConfig", stream: stream) }
      let(:stream) do
        instance_double("Stream",
                        request_rate_limit: 1,
                        rate_limit_unit_seconds: 60)
      end
      let(:records) { %w[record1 record2] }
      describe "#write" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.write(sync_config, records) }.to raise_error("Not implemented")
        end
      end
    end
  end
end
