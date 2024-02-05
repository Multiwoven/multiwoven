# frozen_string_literal: true

RSpec.describe Multiwoven::Integrations do
  describe "::ENABLED_SOURCES" do
    context "when meta.json name is valid" do
      it "creates valid class object for source connector" do
        enabled_source = Multiwoven::Integrations::ENABLED_SOURCES

        enabled_source.each do |source|
          class_name = "Multiwoven::Integrations::Source::#{source}::Client"
          meta_json_name = Object.const_get(class_name).new.send("meta_data")[:data][:name]
          expect(meta_json_name).to eq(source)
          expect(Object.const_defined?("Multiwoven::Integrations::Source::#{meta_json_name}::Client")).to eq(true)
        end
      end

      it "creates valid class object for destination connector" do
        enabled_destinations = Multiwoven::Integrations::ENABLED_DESTINATIONS

        enabled_destinations.each do |destination|
          class_name = "Multiwoven::Integrations::Destination::#{destination}::Client"
          meta_json_name = Object.const_get(class_name).new.send("meta_data")[:data][:name]
          expect(meta_json_name).to eq(destination)
          expect(Object.const_defined?("Multiwoven::Integrations::Destination::#{meta_json_name}::Client")).to eq(true)
        end
      end
    end
  end
end
