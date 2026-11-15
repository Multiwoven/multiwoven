# frozen_string_literal: true

require "rails_helper"

RSpec.describe Middlewares::ActivityCleanupMiddleware do
  let(:middleware) { described_class.new }
  let(:metadata) { double("metadata", to_h: { key: "value" }) }

  it "yields control to the activity" do
    called = false
    middleware.call(metadata) { called = true }
    expect(called).to be true
  end

  it "clears active AR connections after activity completes" do
    expect(ActiveRecord::Base).to receive(:clear_active_connections!)

    middleware.call(metadata) {}
  end

  it "clears connections even when the activity raises an error" do
    expect(ActiveRecord::Base).to receive(:clear_active_connections!)

    expect do
      middleware.call(metadata) { raise StandardError, "activity failed" }
    end.to raise_error(StandardError, "activity failed")
  end
end
