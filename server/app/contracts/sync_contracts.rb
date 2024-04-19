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
        required(:model_id).filled(:integer)
        required(:destination_id).filled(:integer)
        required(:schedule_type).filled(:string)
        optional(:sync_interval).filled(:integer)
        optional(:sync_interval_unit).filled(:string)
        optional(:cron_expression).filled(:string)
        required(:sync_mode).filled(:string)
        required(:stream_name).filled(:string)
        optional(:cursor_field).maybe(:string)

        # update filled with validating array of hashes
        required(:configuration).filled
      end
    end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") unless Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid schedule type") unless Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval) do
      if values[:sync_interval] && values[:sync_interval] <= 0 && values[:schedule_type] == "interval"
        key.failure("must be greater than 0")
      end
    end

    rule(sync: :sync_interval_unit) do
      key.failure("must be present") if values[:sync_interval_unit].nil? && values[:schedule_type] == "interval"
      key.failure("invalid sync interval unit") unless Sync.sync_interval_units.keys.include?(value.downcase)
    end

    rule(sync: :cron_expression) do
      key.failure("must be present") if values[:cron_expression].nil? && values[:schedule_type] == "cron_expression"
      if values[:cron_expression] && !valid_cron_expression?(values[:cron_expression])
        key.failure("invalid cron expression format")
      end
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
        optional(:cron_expression).filled(:string)
        optional(:sync_mode).filled(:string)
        optional(:stream_name).filled(:string)

        # update filled with validating array of hashes
        optional(:configuration).filled
      end
    end

    rule(sync: :sync_mode) do
      key.failure("invalid sync mode") if key? && !Sync.sync_modes.keys.include?(value.downcase)
    end

    rule(sync: :schedule_type) do
      key.failure("invalid schedule type") if key? && !Sync.schedule_types.keys.include?(value.downcase)
    end

    rule(sync: :sync_interval) do
      if key? && value && value <= 0 && values[:sync_interval_unit] && values[:schedule_type] == "interval"
        key.failure("must be greater than 0")
      end
    end

    rule(sync: :sync_interval_unit) do
      if key? && values[:sync_interval_unit] && !Sync.sync_interval_units.keys.include?(value.downcase) &&
         values[:schedule_type] == "interval"
        key.failure("invalid sync interval unit")
      end
    end

    rule(sync: :cron_expression) do
      if key? && values[:cron_expression].nil? && values[:schedule_type] == "cron_expression"
        key.failure("must be present")
        if values[:cron_expression] && !valid_cron_expression?(values[:cron_expression])
          key.failure("invalid cron expression format")
        end

      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Configurations < Dry::Validation::Contract
    params {}
  end
end
