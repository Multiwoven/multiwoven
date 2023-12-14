# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe BaseConnector do
      describe "#connector_spec" do
        xit "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.connector_spec }.to raise_error("Not implemented")
        end
      end

      describe "#check_connection" do
        xit "raises an error for not being implemented" do
          connector = described_class.new
          expect { connector.check_connection({}) }.to raise_error("Not implemented")
        end
      end
    end
  end
end
