# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLog, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:resource_type) }
    it { should validate_presence_of(:workspace_id) }
  end
end
