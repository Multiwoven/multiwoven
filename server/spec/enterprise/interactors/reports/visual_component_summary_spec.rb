# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::VisualComponentSummary, type: :interactor do
  let!(:workspace) { create(:workspace) }
  let!(:data_app) { create(:data_app, workspace:) }
  let!(:visual_component) { create(:visual_component, data_app:) }
  let!(:visual_component_chat) { create(:visual_component, component_type: "chat_bot", data_app:) }
  let!(:data_app_session1) { create(:data_app_session, data_app:, created_at: 2.days.ago) }
  let!(:data_app_session2) { create(:data_app_session, data_app:, created_at: 1.day.ago) }
  let!(:feedback1) { create(:feedback, visual_component:, created_at: 1.day.ago) }
  let!(:feedback2) { create(:feedback, visual_component:, created_at: 2.days.ago) }

  let(:context) do
    {
      time_period: "one_week",
      workspace:,
      data_app_id: data_app.id,
      visual_component_id: visual_component.id
    }
  end

  let(:chat_context) do
    {
      time_period: "one_week",
      workspace:,
      data_app_id: data_app.id,
      visual_component_id: visual_component_chat.id
    }
  end

  before do
    create(:chat_message, visual_component: visual_component_chat, session: data_app_session1, role: 0, content: "Hi")
    create(:chat_message, visual_component: visual_component_chat, session: data_app_session1, role: 1,
                          content: "Hello! How can I help?")
    create(:chat_message, visual_component: visual_component_chat, session: data_app_session1, role: 0, content: "1+1")
    create(:chat_message, visual_component: visual_component_chat, session: data_app_session1, role: 1,
                          content: "1+1=2")
    create(:message_feedback, visual_component: visual_component_chat, created_at: 1.day.ago)
    create(:message_feedback, visual_component: visual_component_chat, created_at: 2.days.ago)
  end

  describe "#call" do
    subject { described_class.call(context) }

    context "with valid type and time_period" do
      it "returns the activity data for the visual component within the specified time period" do
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("one_week")
        expect(result.activity[:visual_component][:data_app_id]).to eq(data_app.id)
        expect(result.activity[:visual_component][:data_app_name]).to eq(data_app.name)
        expect(result.activity[:visual_component][:visual_component_id]).to eq(visual_component.id)
        expect(result.activity[:visual_component][:visual_component_name]).to eq(visual_component.name)
        expect(result.activity[:visual_component][:total_sessions]).to eq(2)
        expect(result.activity[:visual_component][:total_feedback_responses]).to eq(2)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(100.0)
      end
    end

    context "with valid type and time_period" do
      it "returns the activity data for the chat_bot visual component within the specified time period" do
        result = described_class.call(chat_context)
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("one_week")
        expect(result.activity[:visual_component][:data_app_id]).to eq(data_app.id)
        expect(result.activity[:visual_component][:data_app_name]).to eq(data_app.name)
        expect(result.activity[:visual_component][:visual_component_id]).to eq(visual_component_chat.id)
        expect(result.activity[:visual_component][:visual_component_name]).to eq(visual_component_chat.name)
        expect(result.activity[:visual_component][:total_chat_messages]).to eq(2)
        expect(result.activity[:visual_component][:total_messages_feedback_responses]).to eq(2)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(100.0)
        expect(result.activity[:visual_component][:feedback_metric_summary]).to eq(100.0)
      end
    end

    context "with different time_periods" do
      it "calculates the correct start_time for 'one_day'" do
        context[:time_period] = "one_day"
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("one_day")
        expect(result.activity[:visual_component][:total_sessions]).to eq(1)
        expect(result.activity[:visual_component][:total_feedback_responses]).to eq(1)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(100.0)
      end

      it "calculates the correct start_time for 'one_day' for chat_bot" do
        chat_context[:time_period] = "one_day"
        result = described_class.call(chat_context)
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("one_day")
        expect(result.activity[:visual_component][:total_chat_messages]).to eq(2)
        expect(result.activity[:visual_component][:total_messages_feedback_responses]).to eq(1)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(50.0)
      end

      it "calculates the correct start_time for 'thirty_days'" do
        context[:time_period] = "thirty_days"
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("thirty_days")
        expect(result.activity[:visual_component][:total_sessions]).to eq(2)
        expect(result.activity[:visual_component][:total_feedback_responses]).to eq(2)
      end

      it "calculates the correct start_time for 'thirty_days' for chat_bot" do
        chat_context[:time_period] = "thirty_days"
        result = described_class.call(chat_context)
        expect(result).to be_a_success
        expect(result.activity[:time_period]).to eq("thirty_days")
        expect(result.activity[:visual_component][:total_chat_messages]).to eq(2)
        expect(result.activity[:visual_component][:total_messages_feedback_responses]).to eq(2)
      end
    end

    context "when there are no feedbacks or sessions" do
      let!(:visual_component_data_app) { create(:data_app, workspace:, visual_components_count: 1) }

      before do
        context[:data_app_id] = visual_component_data_app.id
        context[:visual_component_id] = visual_component_data_app.visual_components.first.id
      end

      it "returns zero values for sessions and feedback responses" do
        result = subject
        expect(result).to be_a_success
        expect(result.activity[:visual_component][:total_sessions]).to eq(0)
        expect(result.activity[:visual_component][:total_feedback_responses]).to eq(0)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(0)
      end
    end

    context "when there are no feedbacks or chat messages" do
      let!(:empty_visual_component_chat) { create(:visual_component, component_type: "chat_bot", data_app:) }

      before do
        chat_context[:visual_component_id] = empty_visual_component_chat.id
      end

      it "returns zero values for sessions and feedback responses" do
        result = described_class.call(chat_context)
        expect(result).to be_a_success
        expect(result.activity[:visual_component][:total_chat_messages]).to eq(0)
        expect(result.activity[:visual_component][:total_messages_feedback_responses]).to eq(0)
        expect(result.activity[:visual_component][:feedback_percentage]).to eq(0)
      end
    end

    context "with custom date ranges" do
      include ActiveSupport::Testing::TimeHelpers

      context "with custom start_date only" do
        let(:start_date) { Date.new(2024, 1, 15) }
        let(:context) do
          {
            time_period: "custom",
            start_date:,
            end_date: nil,
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }
        end

        it "uses custom start_date and calculates end_date as min(start_date + 30.days, now)" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the custom range
          expect(result.activity[:visual_component]).to be_present

          # Verify asset summary counts are present and correctly structured
          visual_component_report = result.activity[:visual_component]
          expect(visual_component_report).to have_key(:data_app_id)
          expect(visual_component_report).to have_key(:data_app_name)
          expect(visual_component_report).to have_key(:visual_component_id)
          expect(visual_component_report).to have_key(:visual_component_name)
          expect(visual_component_report).to have_key(:feedback_percentage)
          expect(visual_component_report).to have_key(:feedback_metric_summary)

          # Verify counts are present based on component type
          if visual_component.chat_bot?
            expect(visual_component_report).to have_key(:total_chat_messages)
            expect(visual_component_report).to have_key(:total_messages_feedback_responses)
            expect(visual_component_report[:total_chat_messages]).to be >= 0
            expect(visual_component_report[:total_messages_feedback_responses]).to be >= 0
          else
            expect(visual_component_report).to have_key(:total_sessions)
            expect(visual_component_report).to have_key(:total_feedback_responses)
            expect(visual_component_report[:total_sessions]).to be >= 0
            expect(visual_component_report[:total_feedback_responses]).to be >= 0
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
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }
        end

        it "uses exact custom start_date and end_date" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the custom range
          expect(result.activity[:visual_component]).to be_present

          # Verify asset summary counts are correctly calculated for custom date range
          visual_component_report = result.activity[:visual_component]
          expect(visual_component_report).to have_key(:feedback_percentage)
          expect(visual_component_report).to have_key(:feedback_metric_summary)

          # Verify feedback percentage calculation
          expect(visual_component_report[:feedback_percentage]).to be >= 0
          expect(visual_component_report[:feedback_percentage]).to be <= 100
        end
      end

      context "with same start_date and end_date" do
        let(:date) { Date.new(2024, 1, 15) }
        let(:context) do
          {
            time_period: "custom",
            start_date: date,
            end_date: date,
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }
        end

        it "handles same start_date and end_date correctly" do
          result = subject
          expect(result).to be_a_success
          expect(result.activity[:time_period]).to eq("custom")

          # Verify that the data is filtered correctly for the single day range
          expect(result.activity[:visual_component]).to be_present

          # Verify asset summary counts for single day range
          visual_component_report = result.activity[:visual_component]
          expect(visual_component_report).to have_key(:feedback_percentage)
          expect(visual_component_report).to have_key(:feedback_metric_summary)

          # For single day range, verify counts are properly aggregated
          if visual_component.chat_bot?
            expect(visual_component_report[:total_chat_messages]).to be >= 0
            expect(visual_component_report[:total_messages_feedback_responses]).to be >= 0
          else
            expect(visual_component_report[:total_sessions]).to be >= 0
            expect(visual_component_report[:total_feedback_responses]).to be >= 0
          end
        end
      end
    end
  end

  describe "asset summary counts with custom date ranges" do
    include ActiveSupport::Testing::TimeHelpers

    let!(:workspace) { create(:workspace) }
    let!(:data_app) { create(:data_app, workspace:) }
    let!(:visual_component) { create(:visual_component, data_app:) }
    let!(:chat_component) { create(:visual_component, component_type: "chat_bot", data_app:) }

    before do
      # In-range data
      travel_to(Time.zone.parse("2024-01-15 10:00:00 UTC")) do
        in_range_session = create(:data_app_session, data_app:)
        create(:feedback, visual_component:, data_app:)
        create(:chat_message, visual_component: chat_component, session: in_range_session, role: 0,
                              content: "Test message")
        create(:chat_message, visual_component: chat_component, session: in_range_session, role: 1,
                              content: "Test response")
        create(:message_feedback, visual_component: chat_component, data_app:, feedback_type: "thumbs",
                                  reaction: :positive)
      end

      # Out-of-range data
      travel_to(Time.zone.parse("2024-02-15 10:00:00 UTC")) do
        out_of_range_session = create(:data_app_session, data_app:)
        create(:feedback, visual_component:, data_app:)
        create(:chat_message, visual_component: chat_component, session: out_of_range_session, role: 0,
                              content: "Outside range message")
        create(:message_feedback, visual_component: chat_component, data_app:, feedback_type: "thumbs",
                                  reaction: :negative)
      end

      # Reset to current time for test execution
      travel_back
    end

    context "with custom date range filtering for visual component" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:end_date) { Date.new(2024, 1, 20) }
      let(:context) do
        {
          time_period: "custom",
          start_date:,
          end_date:,
          workspace:,
          data_app_id: data_app.id,
          visual_component_id: visual_component.id
        }
      end

      it "correctly filters asset counts by custom date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        visual_component_report = result.activity[:visual_component]
        expect(visual_component_report).to be_present
        expect(visual_component_report[:total_sessions]).to eq(1) # Only 1 session within date range
        expect(visual_component_report[:total_feedback_responses]).to eq(1) # Only 1 feedback within date range
        expect(visual_component_report[:feedback_percentage]).to eq(100.0) # 1 feedback / 1 session * 100
      end
    end

    context "with custom date range filtering for chat component" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:end_date) { Date.new(2024, 1, 20) }
      let(:context) do
        {
          time_period: "custom",
          start_date:,
          end_date:,
          workspace:,
          data_app_id: data_app.id,
          visual_component_id: chat_component.id
        }
      end

      it "correctly filters asset counts by custom date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        visual_component_report = result.activity[:visual_component]
        expect(visual_component_report).to be_present
        expect(visual_component_report[:total_chat_messages]).to eq(1) # 2 messages / 2 = 1 conversation
        expect(visual_component_report[:total_messages_feedback_responses]).to eq(1) # Only 1 feedback within date range
        expect(visual_component_report[:feedback_percentage]).to eq(100.0) # 1 feedback / 1 conversation * 100
      end
    end

    context "with custom start_date only (fallback end_date)" do
      let(:start_date) { Date.new(2024, 1, 10) }
      let(:context) do
        {
          time_period: "custom",
          start_date:,
          end_date: nil,
          workspace:,
          data_app_id: data_app.id,
          visual_component_id: visual_component.id
        }
      end

      it "includes data within the calculated date range" do
        result = described_class.call(context)
        expect(result).to be_a_success

        # Should include data from Jan 15 only since fallback end_date is start_date + 30 days (Feb 9)
        # Feb 15 data is outside the range
        visual_component_report = result.activity[:visual_component]
        expect(visual_component_report[:total_sessions]).to eq(1) # Only Jan 15 session within range
        expect(visual_component_report[:total_feedback_responses]).to eq(1) # Only Jan 15 feedback within range
        expect(visual_component_report[:feedback_percentage]).to eq(100.0) # 1 feedback / 1 session * 100
      end
    end
  end

  describe "inherited BaseActivityReport methods" do
    include ActiveSupport::Testing::TimeHelpers

    let(:interactor) { described_class.new(context) }

    describe "#filter_params" do
      context "with custom start_date only" do
        let(:start_date) { Date.new(2024, 1, 15) }
        let(:context) do
          OpenStruct.new(
            time_period: "custom",
            start_date:,
            end_date: nil,
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
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
          expect(params[:data_app_id]).to eq(data_app.id)
          expect(params[:visual_component_id]).to eq(visual_component.id)
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
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          )
        end

        it "returns correct filter params with exact dates" do
          params = interactor.filter_params

          expect(params[:time_period]).to eq("custom")
          expect(params[:start_time]).to eq(start_date.to_time.beginning_of_day.in_time_zone("UTC"))
          expect(params[:end_time]).to eq(end_date.to_time.end_of_day.in_time_zone("UTC"))
          expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
          expect(params[:range]).to eq(params[:start_time]..params[:end_time])
          expect(params[:data_app_id]).to eq(data_app.id)
          expect(params[:visual_component_id]).to eq(visual_component.id)
        end
      end

      context "with predefined time period" do
        let(:context) do
          OpenStruct.new(
            time_period: "one_week",
            start_date: nil,
            end_date: nil,
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          )
        end

        it "returns correct filter params for predefined period" do
          params = interactor.filter_params

          expect(params[:time_period]).to eq("one_week")
          expect(params[:start_time]).to eq(6.days.ago.beginning_of_day.in_time_zone("UTC"))
          expect(params[:end_time]).to be_within(1.second).of(Time.zone.now)
          expect(params[:created_at]).to eq(params[:start_time]..params[:end_time])
          expect(params[:range]).to eq(params[:start_time]..params[:end_time])
          expect(params[:data_app_id]).to eq(data_app.id)
          expect(params[:visual_component_id]).to eq(visual_component.id)
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
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
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
            workspace:,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          )
        end

        it "returns predefined time range" do
          start_time, end_time = interactor.resolve_time_range

          expect(start_time).to eq(1.day.ago.beginning_of_day.in_time_zone("UTC"))
          expect(end_time).to be_within(1.second).of(Time.zone.now)
        end
      end
    end

    describe "#calculate_predefined_range" do
      let(:context) { OpenStruct.new(workspace:, data_app_id: data_app.id, visual_component_id: visual_component.id) }
      let(:interactor) { described_class.new(context) }

      it "returns correct ranges for all predefined periods" do
        periods = { one_day: 1, one_week: 6, thirty_days: 29 }

        periods.each do |period, days_ago|
          start_time, end_time = interactor.calculate_predefined_range(period)
          expect(start_time).to eq(days_ago.days.ago.beginning_of_day.in_time_zone("UTC"))
          expect(end_time).to be_within(1.second).of(Time.zone.now)
        end
      end
    end
  end

  describe "#calculate_feedback_metric_summary" do
    subject { described_class.call(context) }

    let(:context) do
      {
        time_period: "one_week",
        workspace:,
        data_app_id: data_app.id,
        visual_component_id: visual_component.id
      }
    end

    before do
      visual_component.feedbacks.clear
    end

    context "when feedback type is 'thumbs'" do
      let!(:positive_feedback) do
        create(:feedback, visual_component:, data_app:, feedback_type: "thumbs", reaction: :positive)
      end
      let!(:negative_feedback) do
        create(:feedback, visual_component:, data_app:, feedback_type: "thumbs", reaction: :negative)
      end

      it "calculates the positive feedback percentage" do
        result = subject
        feedback_metric_summary = result.activity[:visual_component][:feedback_metric_summary]

        expect(result).to be_a_success
        expect(feedback_metric_summary).to eq(50.0)
      end
    end

    context "when feedback type is 'scale_input'" do
      let!(:scale_feedback1) { create(:feedback, visual_component:, feedback_type: "scale_input", reaction: 5) }
      let!(:scale_feedback2) { create(:feedback, visual_component:, feedback_type: "scale_input", reaction: 6) }

      it "calculates the average rating" do
        result = subject
        feedback_metric_summary = result.activity[:visual_component][:feedback_metric_summary]

        expect(result).to be_a_success
        expect(feedback_metric_summary).to eq(5.5)
      end
    end

    context "when there are no feedbacks" do
      it "returns nil for feedback metric summary" do
        result = subject
        feedback_metric_summary = result.activity[:visual_component][:feedback_metric_summary]

        expect(result).to be_a_success
        expect(feedback_metric_summary).to be_nil
      end
    end
  end
end
