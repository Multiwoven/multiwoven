# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Temporal initializer" do
  it "configures Temporal with the server environment on boot" do
    expect(Temporal.configuration.host).to eq(ENV.fetch("TEMPORAL_HOST", "localhost"))
    expect(Temporal.configuration.port).to eq(ENV.fetch("TEMPORAL_PORT", 7233).to_i)
    expect(Temporal.configuration.namespace).to eq(ENV.fetch("TEMPORAL_NAMESPACE", "multiwoven-dev"))
    expect(Temporal.configuration.task_queue).to eq(ENV.fetch("TEMPORAL_TASK_QUEUE", "sync-dev"))
  end
end
