# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimit, type: :model do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }

  describe "associations" do
    it { should belong_to(:organization) }
    it { should belong_to(:workspace) }
    it { should belong_to(:created_by).class_name("User").optional }
    it { should have_many(:spending_limit_counters).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:level).with_values(limit: 0, allocation: 1).without_scopes }
    it { should define_enum_for(:scope_type).with_values(%i[workspace workflow data_app user role]) }
    it { should define_enum_for(:limit_type).with_values(%i[cost tokens both]) }
    it { should define_enum_for(:period).with_values(%i[daily weekly monthly]) }
    it { should define_enum_for(:action_on_exhaust).with_values(%i[warn block]) }

    it "keeps the stored value of every scope" do
      expect(described_class.scope_types).to eq(
        "workspace" => 0, "workflow" => 1, "data_app" => 2, "user" => 3, "role" => 4
      )
    end

    it "writes the scope the column already held" do
      limit = create(:spending_limit, workspace:, created_by: user, scope_type: :data_app, scope_ids: ["7"])

      stored = described_class.connection.select_value(
        described_class.sanitize_sql(["SELECT scope_type FROM spending_limits WHERE id = ?", limit.id])
      )

      expect(stored).to eq(2)
    end
  end

  describe "the provider, model and scope lists" do
    it "defaults every one of them to an empty list, which means all of them" do
      limit = create(:spending_limit, workspace:, created_by: user)

      expect(limit.reload).to have_attributes(scope_ids: [], providers: [], models: [])
    end

    it "drops blanks and duplicates and trims what it keeps" do
      limit = create(:spending_limit, workspace:, created_by: user,
                                      providers: ["OpenAI", "", "  Anthropic ", "OpenAI"])

      expect(limit.reload.providers).to eq(%w[OpenAI Anthropic])
    end

    it "turns a nil list back into an empty one" do
      limit = create(:spending_limit, workspace:, created_by: user, models: nil)

      expect(limit.reload.models).to eq([])
    end

    it "stores scope ids as strings whatever it was given" do
      limit = create(:spending_limit, workspace:, created_by: user, scope_type: :data_app, scope_ids: [7, "8"])

      expect(limit.reload.scope_ids).to eq(%w[7 8])
    end

    it "wraps a single value into a list instead of dropping it" do
      limit = create(:spending_limit, workspace:, created_by: user, providers: "OpenAI")

      expect(limit.reload.providers).to eq(%w[OpenAI])
    end

    it "refuses a list longer than the cap" do
      too_many = (1..(described_class::MAX_TARGET_FILTER_ENTRIES + 1)).map(&:to_s)
      limit = build(:spending_limit, workspace:, created_by: user, models: too_many)

      expect(limit).not_to be_valid
      expect(limit.errors[:models]).to include("has too many entries (maximum is 100)")
    end
  end

  describe "validations" do
    subject { build(:spending_limit, workspace:, created_by: user) }

    it { should validate_presence_of(:name) }

    context "when the limit is measured in cost" do
      subject { build(:spending_limit, workspace:, created_by: user, limit_type: :cost) }

      it { should validate_presence_of(:cost_limit) }
      it { should validate_numericality_of(:cost_limit).is_greater_than(0) }
      it { should validate_numericality_of(:token_limit).only_integer.is_greater_than(0).allow_nil }
    end

    context "when the limit is measured in tokens" do
      subject { build(:spending_limit, :with_token_limit, workspace:, created_by: user) }

      it { should validate_presence_of(:token_limit) }
      it { should validate_numericality_of(:token_limit).only_integer.is_greater_than(0) }
      it { should validate_numericality_of(:cost_limit).is_greater_than(0).allow_nil }
    end

    context "when the limit is measured in both" do
      subject { build(:spending_limit, :with_both_limits, workspace:, created_by: user) }

      it { should validate_presence_of(:cost_limit) }
      it { should validate_presence_of(:token_limit) }
    end
  end

  describe "the name the allocation row needs" do
    it "is refused for an ordinary limit" do
      limit = build(:spending_limit, workspace:, created_by: user, name: described_class::ALLOCATION_NAME)

      expect(limit).not_to be_valid
      expect(limit.errors[:name]).to include("is reserved for the workspace allocation")
    end

    it "is refused whatever the case or the padding" do
      limit = build(:spending_limit, workspace:, created_by: user, name: "  workspace ALLOCATION  ")

      expect(limit).not_to be_valid
    end

    it "is allowed for the allocation itself" do
      expect(build(:spending_limit, :allocation, workspace:, created_by: user)).to be_valid
    end

    it "leaves the allocation creatable next to ordinary limits" do
      create(:spending_limit, workspace:, created_by: user, name: "Sales budget")

      expect(build(:spending_limit, :allocation, workspace:, created_by: user)).to be_valid
    end

    it "still refuses two limits of one workspace sharing a name" do
      create(:spending_limit, workspace:, created_by: user, name: "Sales budget")
      duplicate = build(:spending_limit, workspace:, created_by: user, name: "Sales budget")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "alert_thresholds" do
    it "keeps an explicitly empty array, which means no early warnings" do
      limit = create(:spending_limit, workspace:, created_by: user, alert_thresholds: [])

      expect(limit.reload.alert_thresholds).to eq([])
    end

    it "falls back to the column default rather than writing a null" do
      limit = create(:spending_limit, workspace:, created_by: user, alert_thresholds: nil)

      expect(limit.reload.alert_thresholds).to eq(described_class::DEFAULT_ALERT_THRESHOLDS)
    end

    it "sorts and dedupes what it is given" do
      limit = create(:spending_limit, workspace:, created_by: user, alert_thresholds: [90, 80, 90])

      expect(limit.alert_thresholds).to eq([80, 90])
    end

    it "refuses values outside the allowed range" do
      limit = build(:spending_limit, workspace:, created_by: user, alert_thresholds: [0, 80])

      expect(limit).not_to be_valid
      expect(limit.errors[:alert_thresholds]).to include("must be between 1 and 99")
    end

    it "refuses a nested list instead of raising while normalising it" do
      limit = build(:spending_limit, workspace:, created_by: user, alert_thresholds: [[1]])

      expect(limit).not_to be_valid
      expect(limit.errors[:alert_thresholds]).to include("must be a list of numbers")
    end

    it "refuses a list holding a blank" do
      limit = build(:spending_limit, workspace:, created_by: user, alert_thresholds: [nil, 80])

      expect(limit).not_to be_valid
      expect(limit.errors[:alert_thresholds]).to include("must be a list of numbers")
    end
  end

  describe "database constraints" do
    it "refuses a limit whose type has no matching cap, even written around the model" do
      limit = create(:spending_limit, workspace:, created_by: user)
      drop_cost = described_class.sanitize_sql(["UPDATE spending_limits SET cost_limit = NULL WHERE id = ?", limit.id])

      expect { described_class.connection.update(drop_cost) }
        .to raise_error(ActiveRecord::StatementInvalid, /spending_limits_cap_matches_limit_type/)
    end
  end

  describe "scopes" do
    it "separates ordinary limits from the workspace allocation" do
      limit = create(:spending_limit, workspace:, created_by: user)
      allocation = create(:spending_limit, :allocation, workspace:, created_by: user)

      expect(described_class.limits).to contain_exactly(limit)
      expect(described_class.allocations).to contain_exactly(allocation)
    end

    it "returns only the enabled limits of the given workspace" do
      enabled = create(:spending_limit, workspace:, created_by: user)
      create(:spending_limit, :disabled, workspace:, created_by: user)
      create(:spending_limit, workspace: create(:workspace))

      expect(described_class.for_workspace(workspace.id).enabled).to contain_exactly(enabled)
    end
  end
  describe "alert thresholds given a scalar" do
    it "rejects a number instead of raising while normalising it" do
      limit = build(:spending_limit)
      limit.alert_thresholds = 80

      expect(limit).not_to be_valid
      expect(limit.errors[:alert_thresholds]).to include("must be a list of numbers")
    end
  end
end
