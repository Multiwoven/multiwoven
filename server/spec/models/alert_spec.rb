# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alert, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:alert_channels).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:workspace_id) }
    it { should validate_numericality_of(:row_failure_threshold_percent).only_integer.allow_nil }
  end
end
