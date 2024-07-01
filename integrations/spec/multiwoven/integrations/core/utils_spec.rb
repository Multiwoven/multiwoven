# frozen_string_literal: true

module Multiwoven
  module Integrations
    module Core
      RSpec.describe Utils do
        let(:dummy_class) { Class.new { extend Utils } }
        let(:exception_reporter) { double("ExceptionReporter", report: true) }
        let(:logger) { double("Logger", error: true) }
        let(:exception) { StandardError.new("Something went wrong") }

        before do
          allow(Integrations::Service).to receive(:exception_reporter).and_return(exception_reporter)
          allow(Integrations::Service).to receive(:logger).and_return(logger)
        end

        describe "#report_exception" do
          context "when reporter is present and has report method" do
            it "calls the report method on the reporter" do
              expect(exception_reporter).to receive(:report).with(exception, {})
              dummy_class.report_exception(exception)
            end
          end

          context "when reporter is nil" do
            before do
              allow(Integrations::Service).to receive(:exception_reporter).and_return(nil)
            end

            it "does not call the report method" do
              expect { dummy_class.report_exception(exception) }.not_to raise_error
            end
          end
        end
        describe "#hash_to_string" do
          it "returns a string representation of a hash with one key-value pair" do
            hash = { key1: "value1" }
            expect(dummy_class.hash_to_string(hash)).to eq("key1 = value1")
          end
          it "returns a string representation of a hash with multiple key-value pairs" do
            hash = { key1: "value1", key2: "value2", key3: "value3" }
            expect(dummy_class.hash_to_string(hash)).to eq("key1 = value1, key2 = value2, key3 = value3")
          end
          it "returns an empty string for an empty hash" do
            hash = {}
            expect(dummy_class.hash_to_string(hash)).to eq("")
          end
          it "handle hash with different types of values" do
            hash = { key1: 1, key2: 2.5, key3: true, key4: nil }
            expect(dummy_class.hash_to_string(hash)).to eq("key1 = 1, key2 = 2.5, key3 = true, key4 = ")
          end
        end

        describe "#log_request_response" do
          let(:level) { "info" }
          let(:request) { { user_id: 1, action: "create" } }
          let(:response) { { status: "success" } }

          it "creates a LogMessage object with correct attributes" do
            log_message = dummy_class.log_request_response(level, request, response)

            expect(log_message).to be_a(Multiwoven::Integrations::Protocol::LogMessage)
            expect(log_message.level).to eq(level)

            parsed_message = JSON.parse(log_message.message)
            expect(parsed_message["request"]).to eq(request.to_s)
            expect(parsed_message["response"]).to eq(response.to_s)
            expect(parsed_message["level"]).to eq(level)
          end
        end
      end
    end
  end
end
