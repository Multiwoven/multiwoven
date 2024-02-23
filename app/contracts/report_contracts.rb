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
      key.failure("invalid type") unless !key? || Reports::ActivityReport::TYPE.keys.include?(value.downcase.to_sym)
    end

    rule(:metric) do
      unless !key? || Reports::ActivityReport::METRICS.keys.include?(value.downcase.to_sym)
        key.failure("invalid metric")
      end
    end

    rule(:time_period) do
      unless !key? || Reports::ActivityReport::TIME_PERIODS.keys.include?(value.downcase.to_sym)
        key.failure("invalid time_period. Possible values are 'one_week' or 'one_day'")
      end
    end
  end
end
