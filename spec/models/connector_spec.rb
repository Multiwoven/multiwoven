# frozen_string_literal: true

require "rails_helper"

RSpec.describe Connector, type: :model do
  subject { described_class.new }

  context "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_definition_id) }
    it { should validate_presence_of(:connector_type) }
    it { should validate_presence_of(:configuration) }
    it { should validate_presence_of(:name) }
  end

  context "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector_definition) }
    it { should have_many(:models).dependent(:nullify) }
    it { should have_many(:catalog).dependent(:nullify) }
  end
end
