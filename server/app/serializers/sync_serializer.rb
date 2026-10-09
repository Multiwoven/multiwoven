# frozen_string_literal: true

class SyncSerializer < ActiveModel::Serializer
<<<<<<< HEAD
  attributes :id, :source_id, :destination_id, :model_id, :configuration,
=======
  attributes :id, :name, :source_id, :destination_id, :model_id,
>>>>>>> 6e0b1e4c6 (fix(CE): return masked configuration for model (#1840))
             :schedule_type, :sync_mode, :sync_interval, :sync_interval_unit, :cron_expression,
             :stream_name, :status, :cursor_field, :current_cursor_field,
             :updated_at, :created_at

  attribute :configuration do
    object.masked_configuration
  end

  attribute :source do
    ConnectorSerializer.new(object.source).attributes.except(:configuration)
  end

  attribute :destination do
    ConnectorSerializer.new(object.destination).attributes.except(:configuration)
  end

  attribute :model do
    ModelSerializer.new(object.model)
  end
end
