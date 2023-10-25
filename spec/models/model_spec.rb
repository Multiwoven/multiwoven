# frozen_string_literal: true

require "rails_helper"

RSpec.describe Model, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:query) }
    it { should have_many(:syncs).dependent(:nullify) }
  end
end
