# frozen_string_literal: true

module ConnectorDefinitionContracts
  class Index < Dry::Validation::Contract
    params do
      optional(:type).filled(:string)
      optional(:page).filled(:integer)
    end

    rule(:type) do
      if key? && !Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid connector type")
      end
    end
  end

  class Show < Dry::Validation::Contract
    params do
      required(:id).filled(:string)
      required(:type).filled(:string)
    end

    rule(:type) do
      unless Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid connector type")
      end
    end
  end

  class CheckConnection < Dry::Validation::Contract
    params do
      required(:name).filled(:string)
      required(:type).filled(:string)
      required(:connection_spec).filled(:hash)
    end

    rule(:type) do
      unless Multiwoven::Integrations::Protocol::ConnectorType.include?(value.downcase)
        key.failure("invalid connector type")
      end
    end

    rule(:name, :type) do
      if values[:type] == Multiwoven::Integrations::Protocol::ConnectorType["source"]
        unless Multiwoven::Integrations::ENABLED_SOURCES.include?(values[:name])
          key.failure("invalid connector source name")
        end
      elsif values[:type] == Multiwoven::Integrations::Protocol::ConnectorType["destination"]
        unless Multiwoven::Integrations::ENABLED_DESTINATIONS.include?(values[:name])
          key.failure("invalid connector destination name")
        end
      end
    end
  end
end
