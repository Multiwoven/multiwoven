# frozen_string_literal: true

module Reports
  class ActivityReport
    include Interactor

    attr_accessor :workspace_activities, :interval

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
      params = {
        time_period: context.time_period || :one_week,
        metric: context.metric || :all,
        start_time: calculate_start_time(context.time_period || :one_week),
        end_time: Time.zone.now
      }
      params[:created_at] = params[:start_time]..params[:end_time]
      params[:connector_ids] = context.connector_ids if context.connector_ids.present?
      params
    end

    def workspace_activity
      params = filter_params
      @interval = ((params[:end_time] - params[:start_time]) / 60 / SLICE_SIZE).to_i

      @workspace_activities = fetch_activities(params[:created_at])
      filter_activity(params[:connector_ids]) if params[:connector_ids].present?
      context.workspace_activity = send(params[:metric])
      context.workspace_activity = {
        data: send(params[:metric])
      }
    end

    def fetch_activities(created_at)
      scope.sync_runs.where(created_at:)
    end

    def filter_activity(connector_ids)
      @workspace_activities = @workspace_activities.where("source_id IN (:connector_ids) OR
        destination_id IN (:connector_ids)", connector_ids:)
    end

    def scope
      context.workspace if context[:type].match?("workspace_activity")
    end

    def sync_run_triggered
      return [] unless @workspace_activities

      total_grouped = @workspace_activities.group_by_minute(:created_at, n: @interval).count
      failed_grouped = @workspace_activities.where.not(error: nil).group_by_minute(:created_at, n: @interval).count
      success_grouped = @workspace_activities.where(error: nil).group_by_minute(:created_at, n: @interval).count

      total_grouped.map do |time_interval, total_count|
        {
          time_slice: time_interval,
          total_count:,
          failed_count: failed_grouped[time_interval].to_i,
          success_count: success_grouped[time_interval].to_i
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
          failed_count: failed_group_data[time_interval].to_i,
          success_count: successful_group_data[time_interval].to_i
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
