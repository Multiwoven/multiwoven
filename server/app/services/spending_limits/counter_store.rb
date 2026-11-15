# frozen_string_literal: true

module SpendingLimits
  class CounterStore
    Snapshot = Struct.new(:spent_cost, :spent_tokens)

    UPSERT_SQL = <<~SQL.squish
      INSERT INTO spending_limit_counters
             (spending_limit_id, window_start, spent_cost, spent_tokens, request_count, unpriced_requests,
              created_at, updated_at)
      VALUES ($1, $2, $3, $4, 1, $5, NOW(), NOW())
      ON CONFLICT (spending_limit_id, window_start) DO UPDATE
        SET spent_cost        = spending_limit_counters.spent_cost        + EXCLUDED.spent_cost,
            spent_tokens      = spending_limit_counters.spent_tokens      + EXCLUDED.spent_tokens,
            request_count     = spending_limit_counters.request_count     + 1,
            unpriced_requests = spending_limit_counters.unpriced_requests + EXCLUDED.unpriced_requests,
            updated_at        = NOW()
      RETURNING spent_cost - $3   AS before_cost,   spent_cost   AS after_cost,
                spent_tokens - $4 AS before_tokens, spent_tokens AS after_tokens
    SQL

    class << self
      def current_for(limits)
        limits = Array(limits).compact
        return {} if limits.empty?

        clauses = []
        binds = []
        limits.group_by { |limit| limit.period.to_s }.each do |period, group|
          clauses << "(spending_limit_id IN (?) AND window_start = ?)"
          binds << group.map(&:id) << window_start(period)
        end

        SpendingLimitCounter.where(clauses.join(" OR "), *binds).index_by(&:spending_limit_id)
      end

      # Own savepoint: a rejected statement would otherwise abort the caller's transaction.
      def add!(limit, cost:, tokens:, unpriced: false)
        cost = clamp(cost.nil? ? 0 : cost.to_d, "cost", limit)
        tokens = clamp(tokens.to_i, "tokens", limit)
        window = window_start(limit.period)
        result = ActiveRecord::Base.transaction(requires_new: true) do
          ActiveRecord::Base.connection.exec_query(
            UPSERT_SQL,
            "SpendingLimitCounter Upsert",
            upsert_binds(limit.id, window, cost, tokens, unpriced)
          )
        end
        row = result.first
        return [Snapshot.new(0, 0), Snapshot.new(0, 0), window] if row.nil?

        [
          Snapshot.new(row["before_cost"].to_d, row["before_tokens"].to_i),
          Snapshot.new(row["after_cost"].to_d, row["after_tokens"].to_i),
          window
        ]
      end

      def window_start(period, at: Time.current)
        now = at.utc
        case period.to_s
        when "weekly" then now.beginning_of_week(:monday)
        when "monthly" then now.beginning_of_month
        else now.beginning_of_day
        end
      end

      def resets_at(period, at: Time.current)
        start = window_start(period, at:)
        case period.to_s
        when "weekly" then start + 1.week
        when "monthly" then start + 1.month
        else start + 1.day
        end
      end

      private

      # Raw SQL skips the model validations; clamped rather than raised so the call is still counted.
      def clamp(value, name, limit)
        return value unless value.negative?

        Rails.logger.warn("[SpendingLimits::CounterStore] negative #{name} delta #{value} clamped to zero " \
                          "limit_id=#{limit.id}")
        0
      end

      def upsert_binds(limit_id, window, cost, tokens, unpriced)
        [
          bind("spending_limit_id", limit_id, ActiveRecord::Type::Integer.new),
          bind("window_start", window, ActiveRecord::Type::DateTime.new),
          bind("spent_cost", (cost || 0).to_d, ActiveRecord::Type::Decimal.new(precision: 18, scale: 10)),
          bind("spent_tokens", tokens.to_i, ActiveRecord::Type::BigInteger.new),
          bind("unpriced_requests", unpriced ? 1 : 0, ActiveRecord::Type::Integer.new)
        ]
      end

      def bind(name, value, type)
        ActiveRecord::Relation::QueryAttribute.new(name, value, type)
      end
    end
  end
end
