# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    RSpec.describe VectorSourceConnector do
      let(:connector) { described_class.new }

      describe "#search" do
        it "raises an error for not being implemented" do
          expect { connector.search({}) }.to raise_error("Not implemented")
        end
      end
    end
  end
end
