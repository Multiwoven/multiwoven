# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Config do
  describe "#initialize" do
    context "without parameters" do
      it "initializes without errors" do
        expect { Multiwoven::Integrations::Config.new }.not_to raise_error
      end

      it "has a nil logger by default" do
        config = Multiwoven::Integrations::Config.new
        expect(config.logger).to be_nil
      end
    end

    context "with a logger parameter" do
      let(:logger) { double("Logger") }

      it "accepts a logger parameter" do
        config = Multiwoven::Integrations::Config.new(logger: logger)
        expect(config.logger).to eq(logger)
      end
    end
  end

  describe "logger attribute" do
    let(:config) { Multiwoven::Integrations::Config.new }
    let(:new_logger) { double("Logger") }

    it "allows reading and writing the logger" do
      config.logger = new_logger
      expect(config.logger).to eq(new_logger)
    end
  end

  describe "#exception_reporter" do
    let(:logger) { double("Logger") }
    let(:exception_reporter) { double("ExceptionReporter") }
    let(:params) { { logger: logger, exception_reporter: exception_reporter } }
    subject { described_class.new(params) }
    it "can be read" do
      expect(subject.exception_reporter).to eq(exception_reporter)
    end

    it "can be written" do
      new_exception_reporter = double("NewExceptionReporter")
      subject.exception_reporter = new_exception_reporter
      expect(subject.exception_reporter).to eq(new_exception_reporter)
    end
  end
end
