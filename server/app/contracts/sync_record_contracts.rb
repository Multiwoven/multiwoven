# frozen_string_literal: true

module SyncRecordContracts
  class Index < Dry::Validation::Contract
    params do
      required(:sync_id).filled(:integer)
      required(:sync_run_id).filled(:integer)
      optional(:status).filled(:string)
      optional(:page).filled(:integer)
    end

    rule(:status) do
      key.failure("must be a valid status") if value && !SyncRecord.statuses.include?(value)
    end
  end
end
