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
        it "raises an error for write not being implemented" do
          connector = described_class.new
          allow(sync_config).to receive(:sync_mode).and_return("incremental")
          expect { connector.write(sync_config, records) }.to raise_error("Not implemented")
        end
      end

      describe "#tracking_message" do
        let(:log_message_data) do
          Multiwoven::Integrations::Protocol::LogMessage.new(
            name: self.class.name,
            level: "info",
            message: { request: "Sample req", response: "Sample req", level: "info" }.to_json
          )
        end
        it "returns a MultiwovenMessage with tracking information" do
          connector = described_class.new
          success = 2
          failure = 1

          multiwoven_message = connector.tracking_message(success, failure, [log_message_data])

          expect(multiwoven_message).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
          expect(multiwoven_message.type).to eq("tracking")

          tracking_message = multiwoven_message.tracking
          expect(tracking_message).to be_a(Multiwoven::Integrations::Protocol::TrackingMessage)
          expect(tracking_message.success).to eq(success)
          expect(tracking_message.failed).to eq(failure)

          logs = tracking_message.logs
          expect(logs).to be_an(Array)
          expect(logs.size).to eq(1)
          expect(logs.first).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
          expect(logs.first.level).to eq("info")
          expect(logs.first.message).to eq("{\"request\":\"Sample req\",\"response\":\"Sample req\",\"level\":\"info\"}")
        end
      end
    end
  end
end
