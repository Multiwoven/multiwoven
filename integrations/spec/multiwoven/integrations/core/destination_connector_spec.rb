# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe DestinationConnector do
      describe "#write" do
        it "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.write({}, {}) }.to raise_error("Not implemented")
        end
      end
    end
  end
end
