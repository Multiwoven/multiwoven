# frozen_string_literal: true

class SyncRunSerializer < ActiveModel::Serializer
  attributes :id, :sync_id, :status, :started_at, :finished_at, :duration, :total_query_rows, :total_rows,
             :successful_rows, :failed_rows, :error, :created_at, :updated_at
  def duration
    object.finished_at && object.started_at ? object.finished_at - object.started_at : nil
  end
end
