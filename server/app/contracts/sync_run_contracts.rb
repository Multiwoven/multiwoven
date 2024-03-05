# frozen_string_literal: true

module SyncRunContracts
  class Index < Dry::Validation::Contract
    params do
      required(:sync_id).filled(:integer)
      optional(:status).filled(:string)
      optional(:page).filled(:integer)
    end

    rule(:status) do
      key.failure("must be a valid status") if value && !SyncRun.statuses.include?(value)
    end
  end
end
