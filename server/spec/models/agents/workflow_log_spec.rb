# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::WorkflowLog, type: :model do
  let(:workflow_run) { create(:workflow_run) }

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:workflow_run) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
    it { should validate_presence_of(:workflow_id) }
    it { should validate_presence_of(:workflow_run) }
    it { should validate_presence_of(:input) }
    it { should validate_presence_of(:workspace_id) }
  end
end
