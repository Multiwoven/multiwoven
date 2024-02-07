# frozen_string_literal: true

class SyncSerializer < ActiveModel::Serializer
  attributes :id, :source_id, :destination_id, :model_id, :configuration,
             :schedule_type, :sync_mode, :sync_interval, :sync_interval_unit,
             :stream_name, :status

  attribute :source do
    ConnectorSerializer.new(object.source).attributes.except(:configuration)
  end

  attribute :destination do
    ConnectorSerializer.new(object.destination).attributes.except(:configuration)
  end
end
