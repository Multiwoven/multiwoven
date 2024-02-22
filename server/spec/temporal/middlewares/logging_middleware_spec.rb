# frozen_string_literal: true

require "spec_helper"

RSpec.describe Middlewares::LoggingMiddleware do
  let(:app_name) { "TestApp" }
  let(:middleware) { described_class.new(app_name) }
  let(:metadata) { double("metadata", to_h: { key: "value" }) }

  before do
    allow(metadata).to receive(:activity?).and_return(false)
    allow(metadata).to receive(:workflow_task?).and_return(false)
    allow(Temporal.logger).to receive(:info)
    allow(Temporal.logger).to receive(:error)
  end

  context "when metadata represents an activity" do
    before do
      allow(metadata).to receive(:activity?).and_return(true)
      allow(metadata).to receive(:name).and_return("TestActivity")
    end

    it "logs the start and end of the activity" do
      expect(Temporal.logger).to receive(:info).with("[TestApp]: Started TestActivity activity",
                                                     metadata: { key: "value" }).ordered
      expect(Temporal.logger).to receive(:info).with("[TestApp]: Finished TestActivity activity",
                                                     metadata: { key: "value" }).ordered

      middleware.call(metadata) {}
    end
  end

  context "when metadata represents a workflow task" do
    before do
      allow(metadata).to receive(:workflow_task?).and_return(true)
      allow(metadata).to receive(:workflow_name).and_return("TestTask")
    end

    it "logs the start and end of the task" do
      expect(Temporal.logger).to receive(:info).with("[TestApp]: Started TestTask task",
                                                     metadata: { key: "value" }).ordered
      expect(Temporal.logger).to receive(:info).with("[TestApp]: Finished TestTask task",
                                                     metadata: { key: "value" }).ordered

      middleware.call(metadata) {}
    end
  end

  context "when an error occurs" do
    let(:error) { StandardError.new("Test error") }

    before do
      allow(metadata).to receive(:activity?).and_return(true)
      allow(metadata).to receive(:name).and_return("TestActivity")
    end

    it "logs the error and re-raises it" do
      expect(Temporal.logger).to receive(:error).with(
        include("[TestApp]: Error TestActivity activity Error: Test error"), metadata: { key: "value" }
      )

      expect do
        middleware.call(metadata) { raise error }
      end.to raise_error(error)
    end
  end
end
