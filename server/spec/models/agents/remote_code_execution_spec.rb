# frozen_string_literal: true

require "rails_helper"

RSpec.describe Agents::RemoteCodeExecution, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:workflow_run).optional }
    it { is_expected.to belong_to(:workspace) }
    it { is_expected.to belong_to(:component).class_name("Agents::Component").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:mode) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_length_of(:invocation_id).is_at_most(100) }
  end

  describe "enums" do
    it { should define_enum_for(:mode).with_values(test: 0, workflow: 1) }
    it { should define_enum_for(:status).with_values(success: 0, error: 1) }
    it { should define_enum_for(:provider).with_values(aws_lambda: 0) }
  end

  describe "instance methods" do
    let(:execution) { create(:remote_code_execution, execution_time_ms: 1500, status: "success", mode: "test") }

    describe "#duration_seconds" do
      it "returns execution time in seconds" do
        expect(execution.duration_seconds).to eq(1.5)
      end

      it "returns nil if execution_time_ms is nil" do
        execution.update(execution_time_ms: nil)
        expect(execution.duration_seconds).to be_nil
      end
    end
  end
end
