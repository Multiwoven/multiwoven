# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimitCounter, type: :model do
  let(:workspace) { create(:workspace) }
  let(:spending_limit) { create(:spending_limit, workspace:) }

  describe "associations" do
    it { should belong_to(:spending_limit) }
  end

  describe "validations" do
    subject { build(:spending_limit_counter, spending_limit:) }

    it { should validate_presence_of(:window_start) }
    it { should validate_numericality_of(:spent_cost).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:spent_tokens).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:request_count).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:unpriced_requests).only_integer.is_greater_than_or_equal_to(0) }

    it "allows one counter per window of a limit" do
      window = SpendingLimits::CounterStore.window_start(spending_limit.period)
      create(:spending_limit_counter, spending_limit:, window_start: window)
      duplicate = build(:spending_limit_counter, spending_limit:, window_start: window)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:window_start]).to include("has already been taken")
    end

    it "leaves another limit free to use the same window" do
      window = SpendingLimits::CounterStore.window_start(spending_limit.period)
      create(:spending_limit_counter, spending_limit:, window_start: window)
      other = create(:spending_limit, workspace:)

      expect(build(:spending_limit_counter, spending_limit: other, window_start: window)).to be_valid
    end
  end

  describe "#alerted?" do
    it "is true only for a threshold already sent for this window" do
      counter = build(:spending_limit_counter, spending_limit:, alerted_thresholds: [80])

      expect(counter.alerted?(80)).to be(true)
      expect(counter.alerted?(90)).to be(false)
    end

    it "is false for every threshold on a fresh counter" do
      expect(build(:spending_limit_counter, spending_limit:).alerted?(80)).to be(false)
    end
  end

  describe "scopes" do
    it "orders the newest window first" do
      window = SpendingLimits::CounterStore.window_start(spending_limit.period)
      older = create(:spending_limit_counter, spending_limit:, window_start: window - 2.days)
      newer = create(:spending_limit_counter, spending_limit:, window_start: window)

      expect(described_class.recent.to_a).to eq([newer, older])
    end

    it "returns only the counters of the given window" do
      window = SpendingLimits::CounterStore.window_start(spending_limit.period)
      wanted = create(:spending_limit_counter, spending_limit:, window_start: window)
      create(:spending_limit_counter, spending_limit:, window_start: window - 1.day)

      expect(described_class.for_window(window)).to contain_exactly(wanted)
    end
  end

  describe "database constraints" do
    it "refuses a negative total even when written around the model" do
      counter = create(:spending_limit_counter, spending_limit:)

      negative = described_class.sanitize_sql(["UPDATE spending_limit_counters SET spent_cost = -1 WHERE id = ?",
                                               counter.id])

      expect { described_class.connection.update(negative) }
        .to raise_error(ActiveRecord::StatementInvalid, /spending_limit_counters_totals_non_negative/)
    end
  end

  describe "deletion" do
    it "goes with the limit it belongs to" do
      create(:spending_limit_counter, spending_limit:)

      expect { spending_limit.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  describe "#record_threshold!" do
    it "appends the threshold" do
      counter = create(:spending_limit_counter, alerted_thresholds: [80])

      counter.record_threshold!(90)

      expect(counter.reload.alerted_thresholds).to eq([80, 90])
    end

    it "is idempotent, because two workers can settle the same crossing" do
      counter = create(:spending_limit_counter, alerted_thresholds: [80])

      2.times { counter.record_threshold!(90) }

      expect(counter.reload.alerted_thresholds).to eq([80, 90])
    end

    it "keeps the list sorted and unique whatever order they arrive in" do
      counter = create(:spending_limit_counter, alerted_thresholds: [])

      [90, 80, 100, 80].each { |threshold| counter.record_threshold!(threshold) }

      expect(counter.reload.alerted_thresholds).to eq([80, 90, 100])
    end
  end
end
