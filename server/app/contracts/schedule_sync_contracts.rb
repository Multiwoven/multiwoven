# frozen_string_literal: true

module ScheduleSyncContracts
  class Create < Dry::Validation::Contract
    params do
      required(:schedule_sync).hash do
        required(:sync_id).filled(:integer)
      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:schedule_sync).hash do
        required(:sync_id).filled(:integer)
      end
    end
  end
end
