# frozen_string_literal: true

module EnterpriseRoleContracts
  # rubocop:disable Metrics/BlockLength
  class Index < Dry::Validation::Contract
    params do
    end
  end

  class Create < Dry::Validation::Contract
    params do
      required(:role).hash do
        required(:role_name).filled(:string)
        required(:policies).filled(:hash) do
          required(:permissions).filled(:hash) do
            required(:connector_definition).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:connector).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:model).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:report).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync_record).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync_run).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:user).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:workspace).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:data_app).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:audit_logs).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:alerts).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:billing).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:hosted_datastore).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            optional(:spending_limit).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
          end
        end
      end
    end
  end

  class Update < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      required(:role).hash do
        optional(:role_name).filled(:string)
        optional(:policies).filled(:hash) do
          required(:permissions).filled(:hash) do
            required(:connector_definition).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:connector).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:model).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:report).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync_record).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync_run).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:sync).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:user).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:workspace).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:data_app).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:audit_logs).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:alerts).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:billing).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            required(:hosted_datastore).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
            optional(:spending_limit).filled(:hash) do
              required(:create).filled(:bool)
              required(:read).filled(:bool)
              required(:update).filled(:bool)
              required(:delete).filled(:bool)
            end
          end
        end
      end
    end
  end

  class Destroy < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
    end
  end

  class Resources < Dry::Validation::Contract
    params do
    end
  end
end
# rubocop:enable Metrics/BlockLength
