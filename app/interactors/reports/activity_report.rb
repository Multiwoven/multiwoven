# frozen_string_literal: true

module Reports
  class ActivityReport
    include Interactor

    SLICE_SIZE = 30

    TIME_PERIODS = {
      one_week: "one_week",
      one_day: "one_day"
    }.freeze

    METRICS = {
      sync_run_triggered: "sync_run_triggered",
      total_sync_run_rows: "total_sync_run_rows",
      all: "all"
    }.freeze

    TYPE = {
      workspace_activity: "workspace_activity"
    }.freeze

    def call
      type = context.type

      case type.to_sym
      when :workspace_activity
        generate_workspace_activity_report
      else
        raise ArgumentError, "Invalid type: #{type}"
      end
    end

    private

    def generate_workspace_activity_report
      connector_id = context.connector_id
      time_period = context.time_period || :one_week
      metric = context.metric || :all

      start_time = calculate_start_time(time_period)
      end_time = Time.zone.now
      @interval = (((end_time - start_time) / 60) / SLICE_SIZE).to_i
      @sync_activity = fetch_sync_activity(start_time, end_time)
      filter_sync_activity(connector_id) if connector_id.present?

      context.workspace_activity = send(metric)
    end

    def fetch_sync_activity(start_time, end_time)
      context.workspace.sync_runs.where(created_at: start_time..end_time)
    end

    def filter_sync_activity(connector_id)
      @sync_activity = @sync_activity.where("source_id = :connector_id OR destination_id = :connector_id",
                                            connector_id:)
    end

    def sync_run_triggered
      return [] unless @sync_activity

      total_grouped = @sync_activity.group_by_minute(:created_at, n: @interval).count
      error_grouped = @sync_activity.where.not(error: nil).group_by_minute(:created_at, n: @interval).count

      total_grouped.map do |time_interval, total_count|
        {
          time_slice: time_interval,
          total_count:,
          failed_count: error_grouped[time_interval].to_i,
          success_count: total_count - error_grouped[time_interval].to_i
        }
      end
    end

    def total_sync_run_rows
      return [] unless @sync_activity

      grouped_data = @sync_activity.group_by_minute(:created_at, n: @interval)
      successful_group_data = grouped_data.sum(:successful_rows)
      failed_group_data = grouped_data.sum(:failed_rows)

      grouped_data.sum(:total_rows).map do |time_interval, total_count|
        {
          time_slice: time_interval,
          total_count:,
          failed_count: successful_group_data[time_interval].to_i,
          success_count: total_count - failed_group_data[time_interval].to_i
        }
      end
    end

    def all
      {
        sync_run_triggered:,
        total_sync_run_rows:
      }
    end

    def calculate_start_time(time_period)
      case time_period.to_sym
      when :one_week
        1.week.ago.beginning_of_day
      when :one_day
        1.day.ago.beginning_of_day
      end
    end
  end
end
