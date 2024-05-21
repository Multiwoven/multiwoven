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
              expect(exception_reporter).to receive(:report).with(exception)
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
      end
    end
  end
end
