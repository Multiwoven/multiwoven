# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmUsageEvent, type: :model do
  let(:workspace) { create(:workspace) }
  let(:organization) { workspace.organization }

  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:workspace) }
    it { should belong_to(:user).optional }
    it { should belong_to(:role).optional }
    it { should belong_to(:connector).optional }
    it { should belong_to(:pricing).class_name("ModelPricing").optional }
  end

  describe "validations" do
    subject { build(:llm_usage_event, workspace:) }

    it { should validate_presence_of(:request_id) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:model) }

    LlmUsageEvent::TOKEN_COLUMNS.each do |column|
      it { should validate_numericality_of(column).only_integer.is_greater_than_or_equal_to(0) }
    end

    it { should validate_numericality_of(:cost).is_greater_than_or_equal_to(0).allow_nil }

    it "refuses a negative token count, which would subtract from a rebuilt counter" do
      event = build(:llm_usage_event, workspace:, output_tokens: -5)

      expect(event).not_to be_valid
      expect(event.errors[:output_tokens]).to include("must be greater than or equal to 0")
    end

    it "refuses a negative cost" do
      event = build(:llm_usage_event, workspace:, cost: -0.01)

      expect(event).not_to be_valid
      expect(event.errors[:cost]).to include("must be greater than or equal to 0")
    end

    it "still accepts a call that could not be priced" do
      expect(build(:llm_usage_event, :unpriced, workspace:)).to be_valid
    end
  end

  describe "enums" do
    it { should define_enum_for(:source).with_values(%i[workflow data_app execute_model mcp_tool embeddings]) }
    it { should define_enum_for(:token_count_method).with_values(%i[reported estimated hybrid unavailable]) }
    it { should define_enum_for(:status).with_values(%i[success error interrupted]) }
  end

  describe "the ledger is append only" do
    it "is writable until it is persisted" do
      event = build(:llm_usage_event, workspace:)

      expect(event).not_to be_readonly
      expect { event.save! }.to change(described_class, :count).by(1)
    end

    it "is readonly once it is persisted" do
      expect(create(:llm_usage_event, workspace:)).to be_readonly
    end

    it "refuses an update" do
      event = create(:llm_usage_event, workspace:)

      expect { event.update(model: "gpt-4o") }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(event.reload.model).to eq("gpt-4o-mini")
    end

    it "refuses a delete" do
      event = create(:llm_usage_event, workspace:)

      expect { event.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(described_class.exists?(event.id)).to be(true)
    end
  end

  describe "#total_tokens" do
    it "sums every token column" do
      event = build(:llm_usage_event, workspace:, input_tokens: 1000, output_tokens: 200, reasoning_tokens: 30,
                                      cache_read_tokens: 500, cache_write_tokens: 7)

      expect(event.total_tokens).to eq(1737)
    end

    it "is zero for a call that reported nothing" do
      event = build(:llm_usage_event, workspace:, input_tokens: 0, output_tokens: 0, reasoning_tokens: 0,
                                      cache_read_tokens: 0, cache_write_tokens: 0)

      expect(event.total_tokens).to eq(0)
    end
  end

  describe "cost precision" do
    it "keeps a cost as fine as the rates it is worked out from" do
      event = create(:llm_usage_event, workspace:, cost: BigDecimal("0.0000003"))

      expect(event.reload.cost).to eq(BigDecimal("0.0000003"))
    end
  end

  describe "#unpriced?" do
    it "is true only when no cost could be worked out" do
      expect(build(:llm_usage_event, :unpriced, workspace:)).to be_unpriced
      expect(build(:llm_usage_event, workspace:)).not_to be_unpriced
    end
  end

  describe "scopes" do
    it "orders the newest first" do
      older = create(:llm_usage_event, workspace:, created_at: 2.days.ago)
      newer = create(:llm_usage_event, workspace:, created_at: 1.hour.ago)

      expect(described_class.recent.to_a).to eq([newer, older])
    end

    it "puts an event on the window boundary in one window only" do
      boundary = Time.utc(2026, 9, 12)
      create(:llm_usage_event, workspace:, created_at: boundary)

      expect(described_class.created_between(boundary - 1.day, boundary)).to be_empty
      expect(described_class.created_between(boundary, boundary + 1.day).count).to eq(1)
    end

    it "returns only the events inside the given window" do
      inside = create(:llm_usage_event, workspace:, created_at: 2.hours.ago)
      create(:llm_usage_event, workspace:, created_at: 10.days.ago)

      expect(described_class.created_between(1.day.ago, Time.current)).to contain_exactly(inside)
    end

    it "returns only the events that carry no cost" do
      unpriced = create(:llm_usage_event, :unpriced, workspace:)
      create(:llm_usage_event, workspace:)

      expect(described_class.unpriced).to contain_exactly(unpriced)
    end
  end
end
