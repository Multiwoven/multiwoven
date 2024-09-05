# frozen_string_literal: true

module ModelContracts
  class Index < Dry::Validation::Contract
    params do
      optional(:page).filled(:integer)
    end
  end

  class Show < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:model).hash do
        required(:connector_id).filled(:integer)
        required(:name).filled(:string)
        optional(:query).filled(:string)
        required(:query_type).filled(:string)
        required(:primary_key).filled(:string)
        optional(:configuration).filled(:hash)
      end
    end

    rule(model: :query_type) do
      key.failure("invalid query type") unless Multiwoven::Integrations::Protocol::ModelQueryType.include?(value)
    end

    rule(model: :query) do
      if %w[raw_sql dbt soql].include?(values[:model][:query_type])

        if values[:model][:query].present?
          regex = /\b(?:LIMIT|OFFSET)\b\s*\d*\s*;?\s*$/i
          key.failure("Query validation failed: Query cannot contain LIMIT or OFFSET") if value.match?(regex)
        else
          key.failure("Query is required for this query type")
        end
      end
    end

    rule(model: :configuration) do
      if values[:model][:configuration].blank? && (values[:model][:query_type] == "ai_ml")
        key.failure("Configuration is required for this query type")
      end
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:model).hash do
        optional(:connector_id).filled(:integer)
        optional(:name).filled(:string)
        optional(:query).filled(:string)
        optional(:query_type).filled(:string)
        optional(:primary_key).filled(:string)
        optional(:configuration).filled(:hash)
      end
    end

    rule(model: :query_type) do
      unless !key? || Multiwoven::Integrations::Protocol::ModelQueryType.include?(value)
        key.failure("invalid query type")
      end
    end

    rule(model: :query) do
      if values[:model][:query].present?
        regex = /\b(?:LIMIT|OFFSET)\b\s*\d*\s*;?\s*$/i
        key.failure("Query validation failed: Query cannot contain LIMIT or OFFSET") if value.match?(regex)
      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end
end
