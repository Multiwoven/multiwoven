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
      raise ArgumentError, "Invalid type  #{context.type}" unless respond_to?(context.type, true)

      send(context.type)
    end

    private

    def filter_params
      {
        connector_id: context.connector_id,
        time_period: context.time_period || :one_week,
        metric: context.metric || :all
      }
    end

    def workspace_activity
      params = filter_params
      start_time = calculate_start_time(params[:time_period])
      end_time = Time.zone.now
      @interval = ((end_time - start_time) / 60 / SLICE_SIZE).to_i
      @workspace_activities = fetch_activities(start_time, end_time)
      filter_sync_activity(params[:connector_id]) if params[:connector_id].present?
      context.workspace_activity = send(params[:metric])
    end

    def fetch_activities(start_time, end_time)
      scope.sync_runs.where(created_at: start_time..end_time)
    end

    def filter_sync_activity(connector_id)
      @workspace_activities = @workspace_activities.where("source_id = :connector_id OR destination_id = :connector_id",
                                                          connector_id:)
    end

    def scope
      context.workspace if context[:type].match?("workspace_activity")
    end

    def sync_run_triggered
      return [] unless @workspace_activities

      total_grouped = @workspace_activities.group_by_minute(:created_at, n: @interval).count
      error_grouped = @workspace_activities.where.not(error: nil).group_by_minute(:created_at, n: @interval).count

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
      return [] unless @workspace_activities

      grouped_data = @workspace_activities.group_by_minute(:created_at, n: @interval)
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
