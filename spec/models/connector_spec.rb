# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connector, type: :model do
  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_definition_id) }
    it { should validate_presence_of(:connector_type) }
    it { should validate_presence_of(:configuration) }
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector_definition) }
  end
end
