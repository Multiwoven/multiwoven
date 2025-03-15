# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Destination::Sentry::Client do
  let(:connection_config) do
    {
      dsn: "https://598589589@p458458945894589.ingest.co/45894590549",
      environment: "production"
    }
  end
  let(:sync_config) { instance_double("Sync Config", sync_id: 1, sync_run_id: 2) }
  let(:records) do
    [
      instance_double("valid_standard_error"),
      instance_double("valid_argument_error"),
      instance_double("valid_activerecord_error"),
      instance_double("valid_record_not_found_error")
    ]
  end

  let(:sentry_client) { described_class.new(connection_config) }

  describe "#check_connection" do
    context "when successful connection" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          "p458458945894589.ingest.co",
          "POST",
          headers: {
            "Content-Type" => "application/json",
            "X-Sentry-Auth" => "Sentry sentry_version=7, sentry_key=598589589"
          }
        ).and_return({ code: 200 })
      end

      it "returns a successful connection" do
        response = sentry_client.check_connection
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("succeeded")
      end
    end

    context "when connection fails" do
      before do
        allow(Multiwoven::Integrations::Core::HttpClient).to receive(:request).with(
          "p458458945894589.ingest.co",
          "POST",
          headers: {
            "Content-Type" => "application/json",
            "X-Sentry-Auth" => "Sentry sentry_version=7, sentry_key=598589589"
          }
        ).and_return({ code: 404 })
      end

      it "returns a failure status" do
        response = sentry_client.check_connection
        expect(response).to be_a(Multiwoven::Integrations::Protocol::MultiwovenMessage)
        expect(response.connection_status.status).to eq("failed")
      end
    end
  end

  describe "#write" do
    context "when successful write" do
      it "writes errors to Sentry and handles exceptions" do
        expect(sentry_client).to receive(:process_records).with(records)
        sentry_client.write(sync_config, records)
      end
    end

    context "when failure write" do
      before do
        allow(sentry_client).to receive(:process_records).with(records).and_raise(StandardError)
      end
      it "raise error on process record" do
        expect(sentry_client).to receive(:handle_exception).with(
          StandardError, {
            context: "SENTRY:WRITE:EXCEPTION",
            type: "error",
            sync_id: sync_config.sync_id,
            sync_run_id: sync_config.sync_run_id
          }
        )
        sentry_client.write(sync_config, records)
      end
    end
  end

  describe "#process_records" do
    context "when process records success" do
      before do
        allow(::Sentry).to receive(:capture_exception)
      end

      it "captures sentry exception" do
        records.each do |_record|
          expect(::Sentry).to receive(:capture_exception)
        end
        sentry_client.send(:process_records, sync_config, records)
      end
    end

    context "when process sync fails" do
      let(:invalid_records) { [double("InvalidRecord")] }

      before do
        allow(::Sentry).to receive(:capture_exception).and_raise(StandardError)
      end

      it "handles exceptions raised during processing" do
        invalid_records.each do
          expect(sentry_client).to receive(:handle_exception).with(
            StandardError, {
              context: "SENTRY:WRITE:EXCEPTION",
              type: "error",
              sync_id: sync_config.sync_id,
              sync_run_id: sync_config.sync_run_id
            }
          )

          sentry_client.send(:process_records, sync_config, invalid_records)
        end
      end
    end
  end
end
