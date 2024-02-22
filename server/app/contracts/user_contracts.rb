# frozen_string_literal: true

module UserContracts
  class Me < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
    end
  end
end
