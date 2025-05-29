# frozen_string_literal: true

module ConnectorContracts
  class Index < Dry::Validation::Contract
    params do
      optional(:type).filled(:string)
    end

    rule(:type) do
      unless !key? || Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid type")
      end
    end
  end

  class Show < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:connector).hash do
        required(:name).filled(:string)
        required(:connector_name).filled(:string)
        required(:connector_type).filled(:string)
        required(:configuration).filled(:hash)
      end
    end

    rule(connector: :connector_type) do
      unless Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid connector type")
      end
    end

    rule(connector: %i[connector_type connector_name]) do
      if value.first.downcase == Multiwoven::Integrations::Protocol::ConnectorType["source"]
        unless Multiwoven::Integrations::ENABLED_SOURCES.include?(value.second)
          key.failure("invalid connector source name")
        end
      elsif value.first.downcase == Multiwoven::Integrations::Protocol::ConnectorType["destination"]
        unless Multiwoven::Integrations::ENABLED_DESTINATIONS.include?(value.second)
          key.failure("invalid connector destination name")
        end
      end
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:connector).hash do
        optional(:name).filled(:string)
        optional(:connector_name).filled(:string)
        optional(:connector_type).filled(:string)
        optional(:configuration).filled(:hash)
      end
    end

    rule(connector: :connector_type) do
      unless !key? || Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid connector type")
      end
    end

    rule(connector: %i[connector_type connector_name]) do
      if key? && value.first.downcase == Multiwoven::Integrations::Protocol::ConnectorType["source"]
        unless Multiwoven::Integrations::ENABLED_SOURCES.include?(value.second)
          key.failure("invalid connector source name")
        end
      elsif key? && value.first.downcase == Multiwoven::Integrations::Protocol::ConnectorType["destination"]
        unless Multiwoven::Integrations::ENABLED_DESTINATIONS.include?(value.second)
          key.failure("invalid connector destination name")
        end
      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Discover < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class QuerySource < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:query).filled(:string)
    end
  end

  class ExecuteModel < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:payload).filled(:string)
    end

    rule(:payload) do
      JSON.parse(value)
    rescue JSON::ParserError
      key.failure("must be a valid JSON string")
    end
  end
end
