# frozen_string_literal: true

module SyncContracts
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
      required(:sync).hash do
        optional(:source_id).filled(:integer)
        optional(:status).filled(:string)
        required(:model_id).filled(:integer)
        required(:destination_id).filled(:integer)
        required(:schedule_type).filled(:string)
        required(:sync_interval).filled(:integer)
        required(:sync_interval_unit).filled(:string)
        required(:sync_mode).filled(:string)
        required(:stream_name).filled(:string)
        required(:configuration).filled(:hash)
      end
    end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") unless Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid connector type") unless Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval_unit) do
      key.failure("invalid connector type") unless Sync.sync_interval_units.keys.include?(value.downcase)
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:sync).hash do
        optional(:source_id).filled(:integer)
        optional(:model_id).filled(:integer)
        optional(:destination_id).filled(:integer)
        optional(:schedule_type).filled(:string)
        optional(:sync_interval).filled(:integer)
        optional(:sync_interval_unit).filled(:string)
        optional(:status).filled(:string)
        optional(:sync_mode).filled(:string)
        optional(:stream_name).filled(:string)
        optional(:configuration).filled(:hash)
      end
    end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") if key? && !Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid connector type") if key? && !Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval_unit) do
      key.failure("invalid connector type") if key? && !Sync.sync_interval_units.keys.include?(value.downcase)
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end
end
