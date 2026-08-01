# frozen_string_literal: true

module EnterpriseEmbedOriginContracts
  SCOPES = %w[organization workspace].freeze

  class Index < Dry::Validation::Contract
    params do
      optional(:scope).filled(:string, included_in?: SCOPES)
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:origin).filled(:string)
      required(:scope).filled(:string, included_in?: SCOPES)
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:origin).filled(:string)
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end
end
