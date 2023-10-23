# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectorDefinition, type: :model do
  describe "validations" do
    it { should validate_presence_of(:connector_type) }
    it { should validate_presence_of(:spec) }
    it { should validate_presence_of(:meta_data) }
  end

  describe "enums" do
    it { should define_enum_for(:connector_type).with_values(source: 0, destination: 1) }
    it { should define_enum_for(:source_type).with_values(database: 0, api: 1) }
  end
end
