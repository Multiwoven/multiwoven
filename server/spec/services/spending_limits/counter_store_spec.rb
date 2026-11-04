# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimits::CounterStore do
  describe ".window_start" do
    it "is midnight UTC for a daily period" do
      expect(described_class.window_start("daily", at: Time.utc(2026, 9, 12, 17, 45)))
        .to eq(Time.utc(2026, 9, 12))
    end

    it "is Monday for a weekly period" do
      expect(described_class.window_start("weekly", at: Time.utc(2026, 9, 12, 17, 45)))
        .to eq(Time.utc(2026, 9, 7))
    end

    it "is the first of the month for a monthly period" do
      expect(described_class.window_start("monthly", at: Time.utc(2026, 9, 12, 17, 45)))
        .to eq(Time.utc(2026, 9, 1))
    end
  end

  describe ".resets_at" do
    it "is one period after the window start" do
      at = Time.utc(2026, 9, 12, 17, 45)

      expect(described_class.resets_at("daily", at:)).to eq(Time.utc(2026, 9, 13))
      expect(described_class.resets_at("weekly", at:)).to eq(Time.utc(2026, 9, 14))
      expect(described_class.resets_at("monthly", at:)).to eq(Time.utc(2026, 10, 1))
    end
  end

  describe ".add!" do
    let(:workspace) { create(:workspace) }
    let(:limit) { create(:spending_limit, workspace:, period: :daily, cost_limit: 100) }

    it "updates one row for two settlements in the same window" do
      described_class.add!(limit, cost: 2.5, tokens: 100)
      described_class.add!(limit, cost: 1.25, tokens: 50)

      counters = SpendingLimitCounter.where(spending_limit_id: limit.id)
      expect(counters.count).to eq(1)
      expect(counters.first.spent_cost).to eq(BigDecimal("3.75"))
      expect(counters.first.spent_tokens).to eq(150)
      expect(counters.first.request_count).to eq(2)
    end

    it "returns the value before and after" do
      before_first, after_first = described_class.add!(limit, cost: 2.5, tokens: 100)
      before_second, after_second = described_class.add!(limit, cost: 1.25, tokens: 50)

      expect(before_first.spent_cost).to eq(0)
      expect(before_first.spent_tokens).to eq(0)
      expect(after_first.spent_cost).to eq(BigDecimal("2.5"))
      expect(after_first.spent_tokens).to eq(100)

      expect(before_second.spent_cost).to eq(BigDecimal("2.5"))
      expect(before_second.spent_tokens).to eq(100)
      expect(after_second.spent_cost).to eq(BigDecimal("3.75"))
      expect(after_second.spent_tokens).to eq(150)
    end

    it "creates a new row that starts at zero after the window boundary" do
      travel_to(Time.utc(2026, 9, 12, 23, 30)) do
        described_class.add!(limit, cost: 9, tokens: 900)
      end

      before, after = travel_to(Time.utc(2026, 9, 13, 0, 30)) do
        described_class.add!(limit, cost: 1, tokens: 100)
      end

      rows = SpendingLimitCounter.where(spending_limit_id: limit.id).order(:window_start)
      expect(rows.map(&:window_start)).to eq([Time.utc(2026, 9, 12), Time.utc(2026, 9, 13)])
      expect(rows.map(&:spent_cost)).to eq([BigDecimal("9"), BigDecimal("1")])
      expect(before.spent_cost).to eq(0)
      expect(before.spent_tokens).to eq(0)
      expect(after.spent_cost).to eq(BigDecimal("1"))
    end

    it "returns the window it wrote to, so the caller never reads the clock again" do
      before_snapshot, after_snapshot, window = travel_to(Time.utc(2026, 9, 12, 23, 59, 59)) do
        described_class.add!(limit, cost: 1, tokens: 10)
      end

      expect(window).to eq(Time.utc(2026, 9, 12))
      expect(SpendingLimitCounter.find_by(spending_limit_id: limit.id).window_start).to eq(window)
      expect(before_snapshot.spent_cost).to eq(0)
      expect(after_snapshot.spent_cost).to eq(BigDecimal("1"))
    end

    it "counts an unpriced settlement without moving the cost" do
      described_class.add!(limit, cost: 0, tokens: 1200, unpriced: true)

      counter = SpendingLimitCounter.find_by(spending_limit_id: limit.id)
      expect(counter.unpriced_requests).to eq(1)
      expect(counter.spent_cost).to eq(0)
      expect(counter.spent_tokens).to eq(1200)
      expect(counter.request_count).to eq(1)
    end

    it "adds up the unpriced settlements and leaves the priced ones out of that count" do
      described_class.add!(limit, cost: 0, tokens: 100, unpriced: true)
      described_class.add!(limit, cost: 2.5, tokens: 100)
      described_class.add!(limit, cost: 0, tokens: 100, unpriced: true)

      counter = SpendingLimitCounter.find_by(spending_limit_id: limit.id)
      expect(counter.unpriced_requests).to eq(2)
      expect(counter.request_count).to eq(3)
      expect(counter.spent_cost).to eq(BigDecimal("2.5"))
    end

    it "leaves the unpriced count at zero for a priced settlement" do
      described_class.add!(limit, cost: 2.5, tokens: 100)

      expect(SpendingLimitCounter.find_by(spending_limit_id: limit.id).unpriced_requests).to eq(0)
    end

    it "ignores a negative cost instead of letting it subtract from the counter" do
      described_class.add!(limit, cost: 5, tokens: 100)
      before, after = described_class.add!(limit, cost: -3, tokens: 10)

      counter = SpendingLimitCounter.find_by(spending_limit_id: limit.id)
      expect(counter.spent_cost).to eq(BigDecimal("5"))
      expect(counter.spent_tokens).to eq(110)
      expect(counter.request_count).to eq(2)
      expect(before.spent_cost).to eq(BigDecimal("5"))
      expect(after.spent_cost).to eq(BigDecimal("5"))
    end

    it "ignores a negative token count instead of letting it subtract from the counter" do
      described_class.add!(limit, cost: 1, tokens: 100)
      before, after = described_class.add!(limit, cost: 1, tokens: -40)

      counter = SpendingLimitCounter.find_by(spending_limit_id: limit.id)
      expect(counter.spent_tokens).to eq(100)
      expect(counter.spent_cost).to eq(BigDecimal("2"))
      expect(before.spent_tokens).to eq(100)
      expect(after.spent_tokens).to eq(100)
    end

    it "still counts the request a negative delta came in on" do
      described_class.add!(limit, cost: -1, tokens: -1, unpriced: true)

      counter = SpendingLimitCounter.find_by(spending_limit_id: limit.id)
      expect(counter.spent_cost).to eq(0)
      expect(counter.spent_tokens).to eq(0)
      expect(counter.request_count).to eq(1)
      expect(counter.unpriced_requests).to eq(1)
    end

    it "keeps a separate row per period when the same call feeds several limits" do
      monthly = create(:spending_limit, workspace:, period: :monthly, cost_limit: 100)

      described_class.add!(limit, cost: 1, tokens: 10)
      described_class.add!(monthly, cost: 1, tokens: 10)

      expect(SpendingLimitCounter.count).to eq(2)
      expect(described_class.current_for([limit, monthly]).keys).to match_array([limit.id, monthly.id])
    end
  end

  describe ".current_for" do
    let(:workspace) { create(:workspace) }

    it "returns nothing for an empty list" do
      expect(described_class.current_for([])).to eq({})
    end

    it "ignores a counter from a previous window" do
      limit = create(:spending_limit, workspace:, period: :daily, cost_limit: 100)
      create(:spending_limit_counter, spending_limit: limit,
                                      window_start: described_class.window_start("daily") - 1.day, spent_cost: 99)

      expect(described_class.current_for([limit])).to eq({})
    end
  end

  # Racing settlements must not lose an update, so this group needs real connections and no test transaction.
  describe "concurrent settlements" do
    self.use_transactional_tests = false

    # Eager, because a lazy let would be built inside the racing threads themselves.
    let!(:workspace) { create(:workspace) }
    let!(:limit) { create(:spending_limit, workspace:, period: :daily, cost_limit: 1000) }

    after do
      organization = workspace.organization
      membership_ids = WorkspaceUser.where(workspace_id: workspace.id).pluck(:id)
      role_ids = WorkspaceUser.where(id: membership_ids).pluck(:role_id)
      user_ids = WorkspaceUser.where(id: membership_ids).pluck(:user_id) +
                 SpendingLimit.where(workspace_id: workspace.id).pluck(:created_by_id)
      plan_ids = organization.subscriptions.pluck(:plan_id)

      organization.destroy!

      WorkspaceUser.where(id: membership_ids).delete_all
      Role.where(id: role_ids.compact).delete_all
      User.where(id: user_ids.compact.uniq).delete_all
      Billing::Plan.where(id: plan_ids.compact).delete_all
    end

    it "does not lose an update" do
      settlements_per_thread = 25
      barrier = Queue.new

      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            barrier.pop
            settlements_per_thread.times { described_class.add!(limit, cost: 1, tokens: 10) }
          end
        end
      end
      2.times { barrier << :go }
      threads.each(&:join)

      counter = SpendingLimitCounter.find_by(
        spending_limit_id: limit.id, window_start: described_class.window_start("daily")
      )
      expect(counter.spent_cost).to eq(BigDecimal(2 * settlements_per_thread))
      expect(counter.spent_tokens).to eq(2 * settlements_per_thread * 10)
      expect(counter.request_count).to eq(2 * settlements_per_thread)
    end
  end
end
