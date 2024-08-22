# frozen_string_literal: true

module CatalogContracts
  class Create < Dry::Validation::Contract
    params do
      required(:connector_id).filled(:integer)
      required(:catalog).hash do
        required(:json_schema).filled(:hash)
      end
    end
  end
end
