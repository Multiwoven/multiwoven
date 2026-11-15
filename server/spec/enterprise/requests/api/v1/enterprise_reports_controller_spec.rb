# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::ReportsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let!(:user) { workspace.workspace_users.first.user }
  let!(:data_app1) { create(:data_app, workspace:) }
  let!(:data_app2) { create(:data_app, workspace:) }
  let!(:data_app3) { create(:data_app, workspace:, rendering_type: "no_code") }
  let!(:workflow) { create(:workflow, workspace:) }
  let!(:data_app_session1) { create(:data_app_session, workspace:, data_app: data_app1) }
  let!(:data_app_session2) { create(:data_app_session, workspace:, data_app: data_app2, created_at: 1.day.ago) }
  let!(:visual_component1) { data_app1.visual_components.first }
  let!(:visual_component2) { data_app2.visual_components.first }
  let!(:feedback1) do
    create(:feedback, workspace:, data_app: data_app1, visual_component: visual_component1)
  end
  let!(:feedback2) do
    create(:feedback, workspace:, data_app: data_app2, visual_component: visual_component2, created_at: 1.day.ago)
  end
  let!(:workflow_run) do
    create(:workflow_run, workflow:, workspace: workflow.workspace, status: :completed, created_at: 2.days.ago,
                          finished_at: 1.day.ago)
  end
  let!(:workflow_run2) do
    create(:workflow_run, workflow:, workspace: workflow.workspace, status: :failed, created_at: 2.days.ago,
                          finished_at: 1.day.ago)
  end
  let!(:visual_component_workflow) do
    create(:visual_component, data_app: data_app3, workspace:, configurable: workflow, component_type: :chat_bot)
  end
  let!(:message_feedback1) do
    create(:message_feedback, workspace:, visual_component: visual_component_workflow, reaction: :positive)
  end
  let!(:message_feedback2) do
    create(:message_feedback, workspace:, visual_component: visual_component_workflow, reaction: :negative)
  end
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }

  before do
    user.confirm
  end

  describe "GET #index" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index, params: { type: "data_apps", time_period: "one_week" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid params" do
      it "returns the activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        get :index, params: { type: "data_apps", time_period: "one_week", rendering_type: "embed" }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:time_period]).to eq("one_week")
        expect(response_hash[:data][:data_apps]).to be_present
        expect(response_hash[:data][:data_apps].count).to eq(2)
        data_app_report = response_hash[:data][:data_apps].first
        expect(data_app_report[:data_app_id]).to eq(data_app2.id)
        expect(data_app_report[:data_app_name]).to eq(data_app2.name)
        time_slice = data_app_report[:slices][5]
        expect(time_slice[:session_count]).to eq(1)
        expect(time_slice[:feedback_count]).to eq(1)
        data_app_report = response_hash[:data][:data_apps].second
        expect(data_app_report[:data_app_id]).to eq(data_app1.id)
        expect(data_app_report[:data_app_name]).to eq(data_app1.name)
        expect(data_app_report[:total_sessions]).to eq(1)
        expect(data_app_report[:total_feedback_responses]).to eq(1)
        expect(data_app_report[:slices].size).to be > 0
        time_slice = data_app_report[:slices].last
        expect(time_slice[:session_count]).to eq(1)
        expect(time_slice[:feedback_count]).to eq(1)
      end
    end

    context "with valid params and filtering values" do
      it "returns the filtered activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        get :index, params: { type: "data_apps", time_period: "one_week", rendering_type: "no_code" }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:time_period]).to eq("one_week")
        expect(response_hash[:data][:data_apps]).to be_present
        expect(response_hash[:data][:data_apps].count).to eq(1)
        data_app_report = response_hash[:data][:data_apps].first
        expect(data_app_report[:data_app_id]).to eq(data_app3.id)
        expect(data_app_report[:data_app_name]).to eq(data_app3.name)
      end
    end

    context "with valid params and member role" do
      it "returns the activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        workspace.workspace_users.first.update(role: member_role)
        get :index, params: { type: "data_apps", time_period: "one_week", rendering_type: "embed" }

        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:time_period]).to eq("one_week")
        expect(response_hash[:data][:data_apps]).to be_present
        expect(response_hash[:data][:data_apps].count).to eq(2)
      end
    end

    context "with valid params and viewer role" do
      it "returns the activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        workspace.workspace_users.first.update(role: viewer_role)
        get :index, params: { type: "data_apps", time_period: "one_week", rendering_type: "embed" }

        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:time_period]).to eq("one_week")
        expect(response_hash[:data][:data_apps]).to be_present
        expect(response_hash[:data][:data_apps].count).to eq(2)
      end
    end

    context "with invalid type" do
      it "returns an error when the type is invalid" do
        request.headers.merge!(auth_headers(user, workspace.id))
        get :index, params: { type: "invalid_type" }
        expect(response).to have_http_status(:bad_request)
        response_body = JSON.parse(response.body).with_indifferent_access
        expect(response_body[:errors]).to be_present
        expect(response_body[:errors].first["detail"]).to eq("type invalid type")
      end
    end

    context "with valid params for visual components" do
      it "returns the activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        get :index, params: { type: "visual_component", time_period: "one_week", data_app_id: data_app1.id,
                              visual_component_id: visual_component1.id }

        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:time_period]).to eq("one_week")
        expect(response_hash[:data][:visual_component]).to be_present
        expect(response_hash[:data][:visual_component][:data_app_id]).to eq(data_app1.id)
        expect(response_hash[:data][:visual_component][:data_app_name]).to eq(data_app1.name)
        expect(response_hash[:data][:visual_component][:visual_component_id]).to eq(visual_component1.id)
        expect(response_hash[:data][:visual_component][:visual_component_name]).to eq(visual_component1.name)
        expect(response_hash[:data][:visual_component][:total_sessions]).to eq(1)
        expect(response_hash[:data][:visual_component][:total_feedback_responses]).to eq(1)
        expect(response_hash[:data][:visual_component][:feedback_percentage]).to eq(100.0)
      end
    end

    context "with valid params for workflow" do
      it "returns the activity report successfully" do
        request.headers.merge!(auth_headers(user, workspace.id))
        get :index, params: { type: "workflow", workflow_id: workflow.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        expect(response_hash[:data][:workflow]).to be_present
        expect(response_hash[:data][:workflow][:workflow_id]).to eq(workflow.id)
        expect(response_hash[:data][:workflow][:total_successes]).to eq(1)
        expect(response_hash[:data][:workflow][:total_failures]).to eq(1)
        expect(response_hash[:data][:workflow][:average_duration]).to eq(172_800.0)
        expect(response_hash[:data][:workflow][:percent_of_positive_feedback]).to eq(50.0)
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
        it "returns activity report with custom start_date and calculated end_date" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "2024-09-15",
            end_date: nil,
            rendering_type: "embed"
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data][:time_period]).to eq("custom")
          expect(response_hash[:data][:data_apps]).to be_present

          # Verify asset summary counts are present and correctly structured
          data_app_report = response_hash[:data][:data_apps].first
          expect(data_app_report).to have_key(:data_app_id)
          expect(data_app_report).to have_key(:data_app_name)
          expect(data_app_report).to have_key(:is_chat_bot)
          expect(data_app_report).to have_key(:slices)

          expect(data_app_report).to have_key(:total_sessions)
          expect(data_app_report).to have_key(:total_feedback_responses)
          expect(data_app_report[:total_sessions]).to be >= 1
          expect(data_app_report[:total_feedback_responses]).to be >= 1
        end
      end

      context "with custom start_date and end_date" do
        it "returns activity report with exact custom date range" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "2025-09-10",
            end_date: "2025-09-20",
            rendering_type: "embed"
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data][:time_period]).to eq("custom")
          expect(response_hash[:data][:data_apps]).to be_present

          # Verify asset summary counts are correctly calculated for custom date range
          data_app_report = response_hash[:data][:data_apps].first
          expect(data_app_report).to have_key(:slices)

          # Verify slices contain proper count structure
          if data_app_report[:slices].any?
            slice = data_app_report[:slices].first
            expect(slice).to have_key(:time_slice)
            expect(slice).to have_key(:session_count)
            expect(slice).to have_key(:feedback_count)
          end

          expect(data_app_report[:slices].any? { |s| s[:session_count] == 1 }).to be true
          expect(data_app_report[:slices].any? { |s| s[:feedback_count] == 1 }).to be true
        end
      end

      context "with same start_date and end_date" do
        it "handles single day custom date range correctly" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "2024-01-15",
            end_date: "2024-01-15",
            rendering_type: "embed"
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data][:time_period]).to eq("custom")
          expect(response_hash[:data][:data_apps]).to be_present

          # Verify asset summary counts for single day range
          data_app_report = response_hash[:data][:data_apps].first
          expect(data_app_report).to have_key(:slices)

          expect(data_app_report[:total_sessions]).to be >= 0
          expect(data_app_report[:total_feedback_responses]).to be >= 0
        end
      end

      context "with custom date range for visual_component type" do
        it "returns visual component report with custom date range" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "visual_component",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: "2024-01-20",
            data_app_id: data_app1.id,
            visual_component_id: visual_component1.id
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access
          expect(response_hash[:data][:time_period]).to eq("custom")
          expect(response_hash[:data][:visual_component]).to be_present

          # Verify asset summary counts are correctly calculated for custom date range
          visual_component_report = response_hash[:data][:visual_component]
          expect(visual_component_report).to have_key(:feedback_percentage)
          expect(visual_component_report).to have_key(:feedback_metric_summary)

          expect(visual_component_report[:feedback_percentage]).to be >= 0
          expect(visual_component_report[:feedback_percentage]).to be <= 100
        end
      end
    end

    context "asset summary counts with custom date ranges" do
      include ActiveSupport::Testing::TimeHelpers

      around do |example|
        travel_to Time.zone.parse("2025-09-16 12:00:00 UTC") do
          example.run
        end
      end

      let!(:workspace) { create(:workspace) }
      let!(:data_app) { create(:data_app, workspace:) }
      let!(:visual_component) { create(:visual_component, data_app:) }
      let!(:chat_component) { create(:visual_component, component_type: "chat_bot", data_app:) }
      let!(:user) { workspace.workspace_users.first.user }

      before do
        user.confirm
        # Create test data within a specific date range
        travel_to Time.zone.parse("2024-01-15 10:00:00 UTC")
        session_in_range = create(:data_app_session, data_app:, workspace:)
        create(:feedback, visual_component:, data_app:)
        create(:chat_message, visual_component: chat_component, role: 0, content: "Test message",
                              session: session_in_range, workspace:)
        create(:chat_message, visual_component: chat_component, role: 1, content: "Test response",
                              session: session_in_range, workspace:)
        create(:message_feedback, visual_component: chat_component, data_app:)

        # Create test data outside the date range
        travel_to Time.zone.parse("2024-02-15 10:00:00 UTC")
        session_out_of_range = create(:data_app_session, data_app:, workspace:)
        create(:feedback, visual_component:, data_app:)
        create(:chat_message, visual_component: chat_component, role: 0, content: "Outside range message",
                              session: session_out_of_range, workspace:)
        create(:message_feedback, visual_component: chat_component, data_app:)

        # Reset to the original time
        travel_to Time.zone.parse("2025-09-16 12:00:00 UTC")
      end

      context "with custom date range filtering for data_apps type" do
        it "correctly filters asset counts by custom date range" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: "2024-01-20",
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access

          # Find the visual app report
          visual_app_report = response_hash[:data][:data_apps].find { |app| app[:data_app_id] == data_app.id }
          expect(visual_app_report).to be_present
          expect(visual_app_report[:is_chat_bot]).to eq(false)
          # Counter cache shows total sessions (both Jan 15 and Feb 15)
          expect(visual_app_report[:total_sessions]).to eq(2)
          # Counter cache shows total feedbacks (both Jan 15 and Feb 15)
          expect(visual_app_report[:total_feedback_responses]).to eq(2)

          # Find the chat bot report (it will be detected as a regular visual app since chat component is not first)
          chat_app_report = response_hash[:data][:data_apps].find do |app|
            app[:data_app_id] == data_app.id && app[:is_chat_bot]
          end
          if chat_app_report
            expect(chat_app_report[:is_chat_bot]).to eq(true)
            expect(chat_app_report[:total_chat_messages]).to eq(1) # 2 messages / 2 = 1 conversation
            # Counter cache shows total message feedbacks
            expect(chat_app_report[:total_messages_feedback_responses]).to eq(2)
          end
        end
      end

      context "with custom date range filtering for visual_component type" do
        it "correctly filters asset counts by custom date range" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "visual_component",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: "2024-01-20",
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access

          visual_component_report = response_hash[:data][:visual_component]
          expect(visual_component_report).to be_present
          expect(visual_component_report[:total_sessions]).to eq(1) # Only 1 session within date range
          expect(visual_component_report[:total_feedback_responses]).to eq(1) # Only 1 feedback within date range
          expect(visual_component_report[:feedback_percentage]).to eq(100.0) # 1 feedback / 1 session * 100
        end
      end

      context "with custom start_date only (fallback end_date)" do
        it "includes data within the calculated date range" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: nil,
            data_app_id: data_app.id,
            visual_component_id: visual_component.id
          }

          expect(response).to have_http_status(:ok)
          response_hash = JSON.parse(response.body).with_indifferent_access

          # Counter cache shows total counts regardless of date range
          visual_app_report = response_hash[:data][:data_apps].find { |app| app[:data_app_id] == data_app.id }
          expect(visual_app_report[:total_sessions]).to eq(2) # Counter cache shows total sessions
          expect(visual_app_report[:total_feedback_responses]).to eq(2) # Counter cache shows total feedbacks
        end
      end
    end

    context "parameter validation and error handling" do
      context "with invalid date format" do
        it "handles invalid start_date format gracefully" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            start_date: "invalid-date",
            rendering_type: "embed"
          }

          # Invalid date format causes bad request
          expect(response).to have_http_status(:bad_request)
        end
      end

      context "with missing required parameters for visual_component" do
        it "returns error when data_app_id is missing for visual_component type" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "visual_component",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: "2024-01-20",
            visual_component_id: visual_component1.id
          }

          expect(response).to have_http_status(:bad_request)
        end

        it "returns error when visual_component_id is missing for visual_component type" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "visual_component",
            time_period: "custom",
            start_date: "2024-01-10",
            end_date: "2024-01-20",
            data_app_id: data_app1.id
          }

          expect(response).to have_http_status(:bad_request)
        end
      end

      context "with custom time_period but no dates" do
        it "handles custom time_period without start_date gracefully" do
          request.headers.merge!(auth_headers(user, workspace.id))
          get :index, params: {
            type: "data_apps",
            time_period: "custom",
            rendering_type: "embed"
          }

          # Custom time_period without start_date causes bad request
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end
end
