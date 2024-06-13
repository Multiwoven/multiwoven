# frozen_string_literal: true

module WorkspaceContracts
  class Index < Dry::Validation::Contract
    params do
    end
  end

  class Show < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:workspace).schema do
        required(:name).filled(:string)
        required(:organization_id).filled(:integer)
        optional(:description).maybe(:string)
        optional(:region).maybe(:string)
      end
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:workspace).schema do
        optional(:name).maybe(:string)
        optional(:organization_id).filled(:integer)
        optional(:region).maybe(:string)
      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end
end
