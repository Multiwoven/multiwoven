# frozen_string_literal: true

module ReportContracts
  class Index < Dry::Validation::Contract
    params do
      required(:type).filled(:string)
      optional(:metric).filled(:string)
      optional(:connector_id).filled(:integer)
      optional(:time_period).filled(:string)
    end

    rule(:type) do
      key.failure("invalid type") unless !key? || %w[workspace_activity].include?(value.downcase)
    end

    rule(:metric) do
      unless !key? || %w[sync_run_trigged total_sync_run_rows all].include?(value.downcase)
        key.failure("invalid metric")
      end
    end

    rule(:time_period) do
      unless !key? || %w[one_week one_day].include?(value.downcase)
        key.failure("invalid time_period. Possible values are 'one_week' or 'one_day'")
      end
    end
  end
end
