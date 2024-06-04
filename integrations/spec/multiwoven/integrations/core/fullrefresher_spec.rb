# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Core::Fullrefresher do
  let(:sync_config_incremental) { instance_double("SyncConfig", sync_mode: "incremental", stream: stream) }
  let(:sync_config_full_refresh) { instance_double("SyncConfig", sync_mode: "full_refresh", stream: stream) }
  let(:stream) do
    instance_double("Stream",
                    request_rate_limit: 4,
                    rate_limit_unit_seconds: 1,
                    name: "stream_name")
  end
  let(:records) { %w[record1 record2] }

  let(:refresher_class) do
    Class.new do
      prepend Multiwoven::Integrations::Core::Fullrefresher
      prepend Multiwoven::Integrations::Core::RateLimiter

      def write(sync_config, _records, _action = "destination_insert")
        Multiwoven::Integrations::Service.logger.info("Original write called stream_name: #{sync_config.stream.name}")
      end

      def clear_all_records(sync_config)
        expected_clear_message = "Clearing all records for stream: #{sync_config.stream.name}"
        Multiwoven::Integrations::Protocol::ControlMessage.new(
          type: "full_refresh",
          emitted_at: Time.now.to_i,
          status: Multiwoven::Integrations::Protocol::ConnectionStatusType["succeeded"],
          meta: { detail: expected_clear_message }
        ).to_multiwoven_message
      end
    end.new
  end

  let(:failed_refresher) do
    Class.new do
      prepend Multiwoven::Integrations::Core::Fullrefresher

      def write(sync_config, _records, _action = "destination_insert")
        Multiwoven::Integrations::Service.logger.info("Original write called stream_name: #{sync_config.stream.name}")
      end

      def clear_all_records(sync_config)
        expected_clear_message = "Failed to clear all records for stream: #{sync_config.stream.name}"
        Multiwoven::Integrations::Protocol::ControlMessage.new(
          type: "full_refresh",
          emitted_at: Time.now.to_i,
          status: Multiwoven::Integrations::Protocol::ConnectionStatusType["failed"],
          meta: { detail: expected_clear_message }
        ).to_multiwoven_message
      end
    end.new
  end

  describe "#write" do
    context "when sync_mode is full_refresh" do
      it "calls clear_all_records before super method" do
        expected_write_message = "Original write called stream_name: #{stream.name}"
        expect(Multiwoven::Integrations::Service.logger).to receive(:info).with(expected_write_message)
        expect(refresher_class).to receive(:clear_all_records).with(sync_config_full_refresh).once.and_call_original
        refresher_class.write(sync_config_full_refresh, records)
      end
    end

    context "when write is called multiple times with full_refresh" do
      it "calls clear_all_records only once" do
        allow(Multiwoven::Integrations::Service.logger).to receive(:info)
        expect(refresher_class).to receive(:clear_all_records).with(sync_config_full_refresh).once.and_call_original

        3.times { refresher_class.write(sync_config_full_refresh, records) }
      end

      it "it calls clear_all_records and clear failed" do
        expect(refresher_class).not_to receive(:clear_all_records).with(sync_config_full_refresh)
        response = failed_refresher.write(sync_config_full_refresh, records)
        expect(response).to be_instance_of(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.control.status).to eq("failed")
      end
    end

    context "when sync_mode is incremental" do
      it "incremental with refresher_class not calling clear_all_records" do
        expected_write_message = "Original write called stream_name: #{stream.name}"
        allow(Multiwoven::Integrations::Service.logger).to receive(:info)
        expect(Multiwoven::Integrations::Service.logger).to receive(:info).with(expected_write_message)
        expect(refresher_class).not_to receive(:clear_all_records).with(sync_config_incremental)
        refresher_class.write(sync_config_incremental, records)
      end

      it "incremental with failed_refresher not calling clear_all_records" do
        expected_write_message = "Original write called stream_name: #{stream.name}"
        allow(Multiwoven::Integrations::Service.logger).to receive(:info)
        expect(Multiwoven::Integrations::Service.logger).to receive(:info).with(expected_write_message)
        expect(refresher_class).not_to receive(:clear_all_records).with(sync_config_incremental)
        failed_refresher.write(sync_config_incremental, records)
      end
    end
  end
end
