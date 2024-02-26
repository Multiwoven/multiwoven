# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations::Service do
  describe ".initialize" do
    it "yields with config object" do
      expect { |b| described_class.new(&b) }.to yield_with_args(Multiwoven::Integrations::Config)
    end
  end

  describe ".connectors" do
    before do
      stub_const("Multiwoven::Integrations::Service::ENABLED_SOURCES", ["Source1"])
      stub_const("Multiwoven::Integrations::Service::ENABLED_DESTINATIONS", ["Destination1"])
      allow(described_class).to receive(:connector_class).and_return(double("Connector", new: double(
        "Instance", meta_data: { "data": { "icon": "source1.svg" } }, connector_spec: {}
      )))
    end

    it "returns a hash with sources and destinations" do
      expect(described_class.connectors).to have_key(:source)
      expect(described_class.connectors).to have_key(:destination)
    end
  end

  describe ".connector_class" do
    it "constructs the correct class constant" do
      connector = described_class.connector_class("Source", "Snowflake")
      expect(connector).to eq(Multiwoven::Integrations::Source::Snowflake::Client)
    end
  end

  describe ".connectors" do
    it "valid data structure" do
      expected_keys = %i[
        name
        connector_type
        category
        documentation_url
        github_issue_label
        icon
        license
        release_stage
        support_level
        tags
        connector_spec
      ]
      source_connector_keys = described_class.connectors[:source][0].keys
      expect(source_connector_keys).to include(*expected_keys)
    end
  end
end
