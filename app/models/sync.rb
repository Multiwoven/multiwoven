# frozen_string_literal: true

# == Schema Information
#
# Table name: syncs
#
#  id                :bigint           not null, primary key
#  workspace_id      :integer
#  source_id         :integer
#  model_id          :integer
#  destination_id    :integer
#  configuration     :jsonb
#  source_catalog_id :integer
#  schedule_type     :integer
#  schedule_data     :jsonb
#  status            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Sync < ApplicationRecord
  validates :workspace_id, presence: true
  validates :source_id, presence: true
  validates :destination_id, presence: true
  validates :model_id, presence: true
  validates :configuration, presence: true
  validates :schedule_type, presence: true
  validates :sync_interval, presence: true
  validates :sync_interval_unit, presence: true
  validates :stream_name, presence: true
  validates :status, presence: true

  enum :schedule_type, %i[manual automated]
  enum :status, %i[healthy failed aborted in_progress disabled]
  enum :sync_mode, %i[full_refresh incremental]
  enum :sync_interval_unit, %i[hours days weeks]

  belongs_to :workspace
  belongs_to :source, class_name: "Connector"
  belongs_to :destination, class_name: "Connector"
  belongs_to :model
  has_many :sync_runs, dependent: :nullify

  after_initialize :set_defaults, if: :new_record?

  def to_protocol
    catalog = destination.catalog
    Multiwoven::Integrations::Protocol::SyncConfig.new(
      model: model.to_protocol,
      source: source.to_protocol,
      destination: destination.to_protocol,
      stream: catalog.stream_to_protocol(
        catalog.find_stream_by_name(stream_name)
      ),
      sync_mode: Multiwoven::Integrations::Protocol::SyncMode["incremental"],
      destination_sync_mode: Multiwoven::Integrations::Protocol::DestinationSyncMode["insert"]
    )
  end

  def set_defaults
    self.status ||= "healthy"
  end
end
