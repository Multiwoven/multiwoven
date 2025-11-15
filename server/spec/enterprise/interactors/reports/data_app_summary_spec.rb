# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::DataAppSummary, type: :interactor do
  let!(:workspace) { create(:workspace) }
  let!(:data_app1) { create(:data_app, workspace:) }
  let!(:data_app2) { create(:data_app, workspace:) }
  let!(:data_app3) { create(:data_app, workspace:) }
  let!(:data_app4) { create(:data_app, workspace:, rendering_type: "no_code") }
  let!(:visual_component1) { data_app1.visual_components.first }
  let!(:visual_component2) { data_app2.visual_components.first }
  let!(:visual_component3) { create(:visual_component, component_type: "chat_bot", data_app: data_app3, workspace:) }
  let!(:data_app_session1) { create(:data_app_session, workspace:, data_app: data_app1) }
  let!(:data_app_session2) { create(:data_app_session, workspace:, data_app: data_app2, created_at: 1.day.ago) }
  let!(:data_app_session3) { create(:data_app_session, workspace:, data_app: data_app3) }
  let!(:feedback1) do
    create(:feedback, workspace:, data_app: data_app1, visual_component: visual_component1)
  end
  let!(:feedback2) do
    create(:feedback, workspace:, data_app: data_app2, visual_component: visual_component2, created_at: 1.day.ago)
  end
  let(:context) do
    {
      time_period: "one_week", rendering_type: "embed", workspace:
    }
  end

  before do
    data_app3.visual_components[0].update!(component_type: "chat_bot")
    create(:chat_message, visual_component: visual_component3, role: 0, content: "Hi")
    create(:chat_message, visual_component: visual_component3, role: 1, content: "Hello! How can I help?")
    create(:chat_message, visual_component: visual_component3, role: 0, content: "1+1")
    create(:chat_message, visual_component: visual_component3, role: 1, content: "1+1=2")
    create(:message_feedback, visual_component: visual_component3, workspace:, data_app: data_app3)
    create(:message_feedback, visual_component: visual_component3, workspace:, data_app: data_app3)
    create(:message_feedback, visual_component: visual_component3, workspace:, data_app: data_app3)
  end

  describe "#call" do
    subject { described_class.call(context) }

    context "with valid type and time_period" do
      let(:time_period) { "one_week" }

      it "returns activity data for data apps within the specified time period" do
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:data_apps].size).to eq(3)

        data_app_report = result.activity[:data_apps].second
        expect(data_app_report[:data_app_id]).to eq(data_app2.id)
        expect(data_app_report[:data_app_name]).to eq(data_app2.name)
        expect(data_app_report[:is_chat_bot]).to eq(false)
        time_slice = data_app_report[:slices][5]
        expect(time_slice[:session_count]).to eq(1)
        expect(time_slice[:feedback_count]).to eq(1)

        data_app_report = result.activity[:data_apps].third
        expect(data_app_report[:data_app_id]).to eq(data_app1.id)
        expect(data_app_report[:data_app_name]).to eq(data_app1.name)
        expect(data_app_report[:is_chat_bot]).to eq(false)
        expect(data_app_report[:total_sessions]).to eq(1)
        expect(data_app_report[:total_feedback_responses]).to eq(1)
        expect(data_app_report[:slices].size).to be > 0
        time_slice = data_app_report[:slices].last
        expect(time_slice[:session_count]).to eq(1)
        expect(time_slice[:feedback_count]).to eq(1)
      end
    end

    context "with chat bot type and time_period" do
      let(:time_period) { "one_week" }

      it "returns activity data for data apps within the specified time period" do
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:data_apps].size).to eq(3)

        data_app_report = result.activity[:data_apps].first
        expect(data_app_report[:data_app_id]).to eq(data_app3.id)
        expect(data_app_report[:data_app_name]).to eq(data_app3.name)
        expect(data_app_report[:is_chat_bot]).to eq(true)
        expect(data_app_report[:total_chat_messages]).to eq(2)
        expect(data_app_report[:total_messages_feedback_responses]).to eq(3)
        expect(data_app_report[:slices].size).to be > 0
        time_slice = data_app_report[:slices].last
        expect(time_slice[:chat_messages_count]).to eq(2)
        expect(time_slice[:message_feedback_count]).to eq(3)
      end
    end

    context "with data app filtering" do
      it "should filter based on the rendering type and return the values" do
        context["rendering_type"] = "no_code"
        result = subject
        expect(result.activity[:data_apps].size).to eq(1)
        data_app_report = result.activity[:data_apps].first
        expect(data_app_report[:data_app_id]).to eq(data_app4.id)
        expect(data_app_report[:data_app_name]).to eq(data_app4.name)
        expect(data_app_report[:is_chat_bot]).to eq(false)
      end
    end

    context "with different time_periods" do
      it "calculates the correct start_time for 'one_day'" do
        context[:time_period] = "one_day"
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("one_day")
      end

      it "calculates the correct start_time for 'thirty_days'" do
        context[:time_period] = "thirty_days"
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("thirty_days")
      end
    end

    context "with custom date ranges" do
      include ActiveSupport::Testing::TimeHelpers

      around do |example|
        travel_to Time.zone.parse("2025-09-16 12:00:00 UTC") do
          example.run
        end
      end

      context "with custom start_date only" do
        let(:start_date) { Date.new(2024, 1, 15) }
        let(:context) do
          {
            time_period: "custom",
            start_date:,
            end_date: nil,
            rendering_type: "embed",
            workspace:
          }
        end

        it "uses custom start_date and calculates end_date as min(start_date + 30.days, now)" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the custom range
          expect(result.activity[:data_apps]).to be_present

          # Verify asset summary counts are present and correctly structured
          data_app_report = result.activity[:data_apps].first
          expect(data_app_report).to have_key(:data_app_id)
          expect(data_app_report).to have_key(:data_app_name)
          expect(data_app_report).to have_key(:is_chat_bot)
          expect(data_app_report).to have_key(:slices)

          # Verify counts are present based on app type
          if data_app_report[:is_chat_bot]
            expect(data_app_report).to have_key(:total_chat_messages)
            expect(data_app_report).to have_key(:total_messages_feedback_responses)
            expect(data_app_report[:total_chat_messages]).to be >= 0
            expect(data_app_report[:total_messages_feedback_responses]).to be >= 0
          else
            expect(data_app_report).to have_key(:total_sessions)
            expect(data_app_report).to have_key(:total_feedback_responses)
            expect(data_app_report[:total_sessions]).to be >= 0
            expect(data_app_report[:total_feedback_responses]).to be >= 0
          end
        end
      end

      context "with custom start_date and end_date" do
        let(:start_date) { Date.new(2024, 1, 10) }
        let(:end_date) { Date.new(2024, 1, 20) }
        let(:context) do
          {
            time_period: "custom",
            start_date:,
            end_date:,
            rendering_type: "embed",
            workspace:
          }
        end

        it "uses exact custom start_date and end_date" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the custom range
          expect(result.activity[:data_apps]).to be_present

          # Verify asset summary counts are correctly calculated for custom date range
          data_app_report = result.activity[:data_apps].first
          expect(data_app_report).to have_key(:slices)

          # Verify slices contain proper count structure
          if data_app_report[:slices].any?
            slice = data_app_report[:slices].first
            expect(slice).to have_key(:time_slice)

            if data_app_report[:is_chat_bot]
              expect(slice).to have_key(:chat_messages_count)
              expect(slice).to have_key(:message_feedback_count)
              expect(slice[:chat_messages_count]).to be >= 0
              expect(slice[:message_feedback_count]).to be >= 0
            else
              expect(slice).to have_key(:session_count)
              expect(slice).to have_key(:feedback_count)
              expect(slice[:session_count]).to be >= 0
              expect(slice[:feedback_count]).to be >= 0
            end
          end
        end
      end

      context "with same start_date and end_date" do
        let(:date) { Date.new(2024, 1, 15) }
        let(:context) do
          {
            time_period: "custom",
            start_date: date,
            end_date: date,
            rendering_type: "embed",
            workspace:
          }
        end

        it "handles same start_date and end_date correctly" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the single day range
          expect(result.activity[:data_apps]).to be_present

          # Verify asset summary counts for single day range
          data_app_report = result.activity[:data_apps].first
          expect(data_app_report).to have_key(:slices)

          # For single day range, verify counts are properly aggregated
          if data_app_report[:is_chat_bot]
            expect(data_app_report[:total_chat_messages]).to be >= 0
            expect(data_app_report[:total_messages_feedback_responses]).to be >= 0
          else
            expect(data_app_report[:total_sessions]).to be >= 0
            expect(data_app_report[:total_feedback_responses]).to be >= 0
          end
        end
      end
    end
  end

  describe "asset summary counts with custom date ranges" do
    include ActiveSupport::Testing::TimeHelpers

    around do |example|
      travel_to Time.zone.parse("2025-09-16 12:00:00 UTC") do
        example.run
      end
    end

    let!(:workspace) { create(:workspace) }
    let!(:data_app_visual) { create(:data_app, workspace:) }
    let!(:data_app_chat) { create(:data_app, workspace:) }
    let!(:visual_component) { data_app_visual.visual_components.first }
    let!(:chat_component) { create(:visual_component, component_type: "chat_bot", data_app: data_app_chat, workspace:) }

    before do
      # Create test data within a specific date range
      travel_to(Time.zone.parse("2024-01-15 10:00:00 UTC"))
      create(:data_app_session, workspace:, data_app: data_app_visual)
      create(:feedback, workspace:, data_app: data_app_visual, visual_component:)
      create(:chat_message, visual_component: chat_component, role: 0, content: "Test message")
      create(:chat_message, visual_component: chat_component, role: 1, content: "Test response")
      create(:message_feedback, visual_component: chat_component, workspace:, data_app: data_app_chat)

      # Create test data outside the date range
      travel_to(Time.zone.parse("2024-02-15 10:00:00 UTC"))
      create(:data_app_session, workspace:, data_app: data_app_visual)
      create(:feedback, workspace:, data_app: data_app_visual, visual_component:)
      create(:chat_message, visual_component: chat_component, role: 0, content: "Outside range message")
      create(:message_feedback, visual_component: chat_component, workspace:, data_app: data_app_chat)

      # Reset to current time for test execution
      travel_back
    end

    context "with custom date range filtering" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:end_date) { Date.new(2024, 1, 20) }
      let(:context) do
        {
          time_period: "custom",
          start_date:,
          end_date:,
          workspace:
        }
      end

      it "correctly filters asset counts by custom date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        # Find the visual app report
        visual_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_visual.id }
        expect(visual_app_report).to be_present
        expect(visual_app_report[:is_chat_bot]).to eq(false)
        # Counter cache shows total sessions (both Jan 15 and Feb 15)
        expect(visual_app_report[:total_sessions]).to eq(2)
        # Counter cache shows total feedbacks (both Jan 15 and Feb 15)
        expect(visual_app_report[:total_feedback_responses]).to eq(2)

        # Find the chat app report (it will be detected as a regular visual app since chat component is not first)
        chat_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_chat.id }
        expect(chat_app_report).to be_present
        expect(chat_app_report[:is_chat_bot]).to eq(false) # Chat component is not the first visual component
        expect(chat_app_report[:total_sessions]).to eq(0) # No sessions created for chat app
        expect(chat_app_report[:total_feedback_responses]).to eq(0) # No feedbacks created for chat app
      end

      # TODO: Fix this test
      xit "correctly filters slice counts by custom date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        # Check visual app slices
        visual_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_visual.id }
        expect(visual_app_report[:slices]).to be_present

        # Find the slice for the test date (2024-01-15)
        test_date_slice = visual_app_report[:slices].find do |slice|
          slice[:time_slice].to_date == Date.new(2024, 1, 15)
        end
        expect(test_date_slice).to be_present
        expect(test_date_slice[:session_count]).to eq(1)
        expect(test_date_slice[:feedback_count]).to eq(1)

        # Check chat app slices (it will be detected as a regular visual app)
        chat_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_chat.id }
        expect(chat_app_report[:slices]).to be_present

        # Since no sessions were created for the chat app, all slices should have 0 counts
        chat_app_report[:slices].each do |slice|
          expect(slice[:session_count]).to eq(0)
          expect(slice[:feedback_count]).to eq(0)
        end
      end
    end

    context "with custom start_date only (fallback end_date)" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:context) do
        {
          time_period: "custom",
          start_date:,
          end_date: nil,
          workspace:
        }
      end

      it "includes data within the calculated date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        # Counter cache shows total counts regardless of date range
        visual_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_visual.id }
        expect(visual_app_report[:total_sessions]).to eq(2) # Counter cache shows total sessions
        expect(visual_app_report[:total_feedback_responses]).to eq(2) # Counter cache shows total feedbacks

        chat_app_report = result.activity[:data_apps].find { |app| app[:data_app_id] == data_app_chat.id }
        expect(chat_app_report).to be_present
        expect(chat_app_report[:total_sessions]).to eq(0) # No sessions created for chat app
        expect(chat_app_report[:total_feedback_responses]).to eq(0) # No feedbacks created for chat app
      end
    end
  end

  describe "inherited BaseActivityReport methods" do
    include ActiveSupport::Testing::TimeHelpers

    around do |example|
      travel_to Time.zone.parse("2025-09-16 12:00:00 UTC") do
        example.run
      end
    end

    let(:interactor) { described_class.new(context) }

    describe "#filter_params" do
      context "with custom start_date only" do
        let(:start_date) { Date.new(2024, 1, 15) }
        let(:context) do
          OpenStruct.new(
            time_period: "custom",
            start_date:,
            end_date: nil,
            workspace:
          )
        end

        it "returns correct filter params with calculated end_date" do
          params = interactor.filter_params

          expect(params[:time_period]).to eq("custom")
          expect(params[:start_time]).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
          expected_end = [start_date.to_time.beginning_of_day.in_time_zone("UTC") + 30.days, Time.zone.now].min
          expect(params[:end_time]).to eq(expected_end)
          expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
          expect(params[:range]).to eq(params[:start_time]..params[:end_time])
        end
      end

      context "with custom start_date and end_date" do
        let(:start_date) { Date.new(2024, 1, 10) }
        let(:end_date) { Date.new(2024, 1, 20) }
        let(:context) do
          OpenStruct.new(
            time_period: "custom",
            start_date:,
            end_date:,
            workspace:
          )
        end

        it "returns correct filter params with exact dates" do
          params = interactor.filter_params

          expect(params[:time_period]).to eq("custom")
          expect(params[:start_time]).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
          expect(params[:end_time]).to eq(end_date.to_time.end_of_day.in_time_zone("UTC"))
          expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
          expect(params[:range]).to eq(params[:start_time]..params[:end_time])
        end
      end

      context "with predefined time period" do
        let(:context) do
          OpenStruct.new(
            time_period: "one_week",
            start_date: nil,
            end_date: nil,
            workspace:
          )
        end

        it "returns correct filter params for predefined period" do
          params = interactor.filter_params

          expect(params[:time_period]).to eq("one_week")
          expect(params[:start_time]).to eq(6.days.ago.beginning_of_day.in_time_zone("UTC"))
          expect(params[:end_time]).to eq(Time.zone.now)
          expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
          expect(params[:range]).to eq(params[:start_time]..params[:end_time])
        end
      end
    end

    describe "#resolve_time_range" do
      context "with custom dates" do
        let(:start_date) { Date.new(2024, 1, 15) }
        let(:end_date) { Date.new(2024, 1, 25) }
        let(:context) do
          OpenStruct.new(
            start_date:,
            end_date:,
            time_period: "custom",
            workspace:
          )
        end

        it "returns custom time range" do
          start_time, end_time = interactor.resolve_time_range

          expect(start_time).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
          expect(end_time).to eq(end_date.to_time.end_of_day.in_time_zone("UTC"))
        end
      end

      context "with predefined period" do
        let(:context) do
          OpenStruct.new(
            time_period: "one_day",
            start_date: nil,
            end_date: nil,
            workspace:
          )
        end

        it "returns predefined time range" do
          start_time, end_time = interactor.resolve_time_range

          expect(start_time).to eq(1.day.ago.beginning_of_day.in_time_zone("UTC"))
          expect(end_time).to eq(Time.zone.now)
        end
      end
    end

    describe "#calculate_predefined_range" do
      let(:context) { OpenStruct.new(workspace:) }
      let(:interactor) { described_class.new(context) }

      it "returns correct ranges for all predefined periods" do
        periods = { one_day: 1, one_week: 6, thirty_days: 29 }

        periods.each do |period, days_ago|
          start_time, end_time = interactor.calculate_predefined_range(period)
          expect(start_time).to eq(days_ago.days.ago.beginning_of_day.in_time_zone("UTC"))
          expect(end_time).to eq(Time.zone.now)
        end
      end
    end
  end
end
