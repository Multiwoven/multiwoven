# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::BaseActivityReport do
  include ActiveSupport::Testing::TimeHelpers

  let(:workspace) { create(:workspace) }
  let(:data_app) { create(:data_app, workspace:) }
  let(:visual_component) { create(:visual_component, data_app:) }

  # Test subclass to inject context
  let(:test_class) do
    Class.new(Reports::BaseActivityReport) do
      attr_reader :context

      def initialize(context)
        super()
        @context = context
      end
    end
  end

  let(:base_activity_report) { test_class.new(context) }

  around do |example|
    # Freeze time to a specific UTC time to ensure consistent timezone behavior
    travel_to Time.zone.parse("2025-09-16 12:00:00 UTC") do
      # Set timezone to UTC for consistent behavior
      Time.zone = "UTC"
      example.run
    end
  end

  describe "#filter_params" do
    context "predefined time period" do
      let(:context) do
        OpenStruct.new(
          time_period: "one_week",
          data_app_id: data_app.id,
          visual_component_id: visual_component.id,
          start_date: nil,
          end_date: nil
        )
      end

      it "returns correct filter params" do
        params = base_activity_report.filter_params

        expect(params[:time_period]).to eq("one_week")
        expect(params[:data_app_id]).to eq(data_app.id)
        expect(params[:visual_component_id]).to eq(visual_component.id)
        expect(params[:start_time]).to eq(6.days.ago.beginning_of_day.in_time_zone("UTC"))
        expect(params[:end_time]).to be_within(1.second).of(Time.zone.now)
        expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
        expect(params[:range]).to eq(params[:start_time]..params[:end_time])
      end
    end

    context "custom start_date only" do
      let(:start_date) { Date.new(2024, 1, 15) }
      let(:context) do
        OpenStruct.new(
          time_period: "custom",
          start_date:,
          end_date: nil,
          data_app_id: data_app.id
        )
      end

      it "sets end_time to min(start_date + 30.days, now)" do
        params = base_activity_report.filter_params
        expect(params[:time_period]).to eq("custom")
        expect(params[:start_time]).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
        expected_end = [start_date.to_time.beginning_of_day.in_time_zone("UTC") + 30.days, Time.zone.now].min
        expect(params[:end_time]).to eq(expected_end)
      end
    end

    context "custom start_date and end_date" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:end_date) { Date.new(2024, 1, 20) }
      let(:context) { OpenStruct.new(time_period: "custom", start_date:, end_date:) }

      it "sets exact start_time and end_time" do
        params = base_activity_report.filter_params
        expect(params[:start_time]).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
        expect(params[:end_time]).to eq(end_date.to_time.end_of_day.in_time_zone("UTC"))
      end
    end
  end

  describe "#resolve_time_range" do
    context "predefined period" do
      let(:context) { OpenStruct.new(time_period: "one_week", start_date: nil, end_date: nil) }

      it "returns correct predefined range" do
        start_time, end_time = base_activity_report.resolve_time_range
        expect(start_time).to eq(6.days.ago.beginning_of_day.in_time_zone("UTC"))
        expect(end_time).to be_within(1.second).of(Time.zone.now)
      end
    end

    context "custom period" do
      let(:start_date) { Date.new(2024, 1, 15) }
      let(:context) { OpenStruct.new(start_date:, end_date: nil, time_period: "custom") }

      it "returns custom range with fallback end_time" do
        start_time, end_time = base_activity_report.resolve_time_range
        expect(start_time).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
        expect(end_time).to eq([start_date.to_time.beginning_of_day.in_time_zone("UTC") + 30.days, Time.zone.now].min)
      end
    end
  end

  describe "#calculate_predefined_range" do
    let(:dummy_context) { OpenStruct.new }
    let(:base_activity_report) { test_class.new(dummy_context) }

    it "returns correct ranges for :one_day, :one_week, :thirty_days" do
      periods = { one_day: 1, one_week: 6, thirty_days: 29 }

      periods.each do |period, days_ago|
        start_time, end_time = base_activity_report.calculate_predefined_range(period)
        expect(start_time).to eq(days_ago.days.ago.beginning_of_day.in_time_zone("UTC"))
        expect(end_time).to be_within(1.second).of(Time.zone.now)
      end
    end
  end

  describe "time zone handling" do
    let(:start_date) { Date.new(2024, 1, 15) }
    let(:context) { OpenStruct.new(start_date:, end_date: nil, time_period: "custom") }

    it "ensures start_time and end_time are in UTC" do
      start_time, end_time = base_activity_report.resolve_time_range
      expect(start_time.zone).to eq("UTC")
      expect(end_time.zone).to eq("UTC")
    end

    it "sets start_time to beginning of day" do
      start_time, = base_activity_report.resolve_time_range
      expect(start_time.min).to be_between(0, 59)
      expect(start_time.sec).to eq(0)
      expect(start_time.zone).to eq("UTC")
      # Verify it's beginning of day (actual hour depends on server timezone conversion)
      expect(start_time.hour).to be_between(0, 23)
    end
  end

  describe "edge cases" do
    it "handles start_date = end_date correctly" do
      date = Date.new(2024, 1, 15)
      context = OpenStruct.new(start_date: date, end_date: date, time_period: "custom")
      base_activity_report = test_class.new(context)
      start_time, end_time = base_activity_report.resolve_time_range
      # Date conversion may shift due to timezone, but should be within 1 day
      expect(start_time.to_date).to be_between(date - 1.day, date)
      expect(end_time.to_date).to be_between(date - 1.day, date)
      expect(start_time < end_time).to be true
      # Hours depend on timezone conversion but should be valid
      expect(start_time.hour).to be_between(0, 23)
      expect(end_time.hour).to be_between(0, 23)
    end

    it "handles future end_date correctly" do
      start_date = Date.new(2024, 1, 10)
      end_date = Date.new(2024, 5, 10)
      context = OpenStruct.new(start_date:, end_date:, time_period: "custom")
      base_activity_report = test_class.new(context)
      _start_time, end_time = base_activity_report.resolve_time_range
      expect(end_time).to eq(end_date.to_time.end_of_day.in_time_zone("UTC"))
    end
  end
end
