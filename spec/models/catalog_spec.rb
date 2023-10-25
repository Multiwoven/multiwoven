# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:connector) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_presence_of(:connector_id) }
    it { should validate_presence_of(:catalog) }
    it { should validate_presence_of(:catalog_hash) }
  end
end
