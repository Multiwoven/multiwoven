# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::DataAppSessionsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let!(:workspace_id) { workspace.id }
  let(:viewer_role) { create(:role, :viewer) }
  let(:member_role) { create(:role, :member) }
  let!(:data_app) { create(:data_app, workspace:, visual_components_count: 1) }
  let(:data_app_session1) { create(:data_app_session, data_app:, workspace:) }
  let(:data_app_session2) { create(:data_app_session, data_app:, workspace:, title: "Title 2") }

  before do
    user.confirm
    create(:chat_message, workspace:, role: 0, content: "Hello.", session: data_app_session1,
                          visual_component: data_app.visual_components.first)
    create(
      :chat_message,
      workspace:,
      role: 1,
      content: "Hello! How can I assist you today?",
      session: data_app_session1,
      visual_component: data_app.visual_components.first
    )
    create(:chat_message, workspace:, role: 0, content: "return chart data", session: data_app_session2,
                          visual_component: data_app.visual_components.first)
    create(
      :chat_message,
      workspace:,
      role: 1,
      content: {
        type: "chart",
        message: "chart number: 0",
        chart_data: [
          {
            data: [],
            x_axis: "species",
            y_axis: "risk_score",
            chart_type: "table",
            sql_query: "",
            groups: nil
          }
        ]
      }.to_json,
      session: data_app_session2,
      visual_component: data_app.visual_components.first
    )
  end

  describe "GET #index" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user hasn't accepted eula" do
      it "returns forbidden" do
        user.update!(eula_accepted: false)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when it is an authenticated user" do
      before do
        request.headers.merge!(auth_headers(user, workspace_id))
      end

      it "returns success and get all data app sessions" do
        get :index
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        expect(response_hash["data"].count).to eql(2)
        expect(response_hash["data"].first["id"]).to eql(data_app_session2.id.to_s)
        expect(response_hash["data"].first["attributes"]["session_id"]).to eql(data_app_session2.session_id)
        expect(response_hash["data"].first["attributes"]["title"]).to eql(data_app_session2.title)
        expect(response_hash["data"].last["id"]).to eql(data_app_session1.id.to_s)
        expect(response_hash["data"].last["attributes"]["session_id"]).to eql(data_app_session1.session_id)
        expect(response_hash["data"].last["attributes"]["title"]).to eql(data_app_session1.title)
      end

      it "returns success and get all data app sessions for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get :index
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        expect(response_hash["data"].count).to eql(2)
        expect(response_hash["data"].first["id"]).to eql(data_app_session2.id.to_s)
        expect(response_hash["data"].first["attributes"]["session_id"]).to eql(data_app_session2.session_id)
        expect(response_hash["data"].first["attributes"]["title"]).to eql(data_app_session2.title)
        expect(response_hash["data"].last["id"]).to eql(data_app_session1.id.to_s)
        expect(response_hash["data"].last["attributes"]["session_id"]).to eql(data_app_session1.session_id)
        expect(response_hash["data"].last["attributes"]["title"]).to eql(data_app_session1.title)
      end

      it "returns success and get all data app sessions for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get :index
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        expect(response_hash["data"].count).to eql(2)
        expect(response_hash["data"].first["id"]).to eql(data_app_session2.id.to_s)
        expect(response_hash["data"].first["attributes"]["session_id"]).to eql(data_app_session2.session_id)
        expect(response_hash["data"].first["attributes"]["title"]).to eql(data_app_session2.title)
        expect(response_hash["data"].last["id"]).to eql(data_app_session1.id.to_s)
        expect(response_hash["data"].last["attributes"]["session_id"]).to eql(data_app_session1.session_id)
        expect(response_hash["data"].last["attributes"]["title"]).to eql(data_app_session1.title)
      end
    end
  end

  describe "GET #chat messages" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :chat_messages, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user hasn't accepted eula" do
      it "returns forbidden" do
        user.update!(eula_accepted: false)
        request.headers.merge!(auth_headers(user, workspace_id))
        get :chat_messages, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when it is an authenticated user" do
      before do
        request.headers.merge!(auth_headers(user, workspace_id))
      end

      it "returns success and get chat message history" do
        get :chat_messages, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(["Hello.", "Hello! How can I assist you today?"]).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session1.id)
          end
        end

        expected_contents = [
          "return chart data",
          {
            type: "chart",
            message: "chart number: 0",
            chart_data: [
              {
                data: [],
                x_axis: "species",
                y_axis: "risk_score",
                chart_type: "table",
                sql_query: "",
                groups: nil
              }
            ]
          }.to_json
        ]

        get :chat_messages, params: { id: data_app_session2.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(expected_contents).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session2.id)
          end
        end
      end

      it "returns success and get chat message history for member role" do
        workspace.workspace_users.first.update(role: member_role)
        get :chat_messages, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(["Hello.", "Hello! How can I assist you today?"]).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session1.id)
          end
        end

        expected_contents = [
          "return chart data",
          {
            type: "chart",
            message: "chart number: 0",
            chart_data: [
              {
                data: [],
                x_axis: "species",
                y_axis: "risk_score",
                chart_type: "table",
                sql_query: "",
                groups: nil
              }
            ]
          }.to_json
        ]

        get :chat_messages, params: { id: data_app_session2.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(expected_contents).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session2.id)
          end
        end
      end

      it "returns success and get chat message history for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        get :chat_messages, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access
        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(["Hello.", "Hello! How can I assist you today?"]).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session1.id)
          end
        end

        expected_contents = [
          "return chart data",
          {
            type: "chart",
            message: "chart number: 0",
            chart_data: [
              {
                data: [],
                x_axis: "species",
                y_axis: "risk_score",
                chart_type: "table",
                sql_query: "",
                groups: nil
              }
            ]
          }.to_json
        ]

        get :chat_messages, params: { id: data_app_session2.id }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        response_hash.map do |record|
          record[1].each do |data|
            expect(%w[user assistant]).to include(data["attributes"]["role"])
            expect(expected_contents).to include(data["attributes"]["content"])
            expect(data["attributes"]["data_app_session_id"]).to eql(data_app_session2.id)
          end
        end
      end
    end
  end

  describe "PATCH #update_title" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        patch :update_title, params: { id: data_app_session1.id, title: "Update Title" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user hasn't accepted eula" do
      it "returns forbidden" do
        user.update!(eula_accepted: false)
        request.headers.merge!(auth_headers(user, workspace_id))
        patch :update_title, params: { id: data_app_session1.id, title: "Update Title" }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when it is an authenticated user" do
      before do
        request.headers.merge!(auth_headers(user, workspace_id))
      end

      it "returns success and change title" do
        patch :update_title, params: { id: data_app_session1.id, title: "Update Title" }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body)

        expect(response_hash["data"]["attributes"]["title"]).to eql("Update Title")
        expect(response_hash["data"]["id"]).to eql(data_app_session1.id.to_s)
        expect(data_app_session1.reload.title).to eql("Update Title")
      end

      it "returns success and get chat message history for member role" do
        workspace.workspace_users.first.update(role: member_role)
        patch :update_title, params: { id: data_app_session1.id, title: "Update Title" }
        expect(response).to have_http_status(:ok)
        response_hash = JSON.parse(response.body).with_indifferent_access

        expect(response_hash["data"]["attributes"]["title"]).to eql("Update Title")
        expect(response_hash["data"]["id"]).to eql(data_app_session1.id.to_s)
        expect(data_app_session1.reload.title).to eql("Update Title")
      end

      it "returns forbidden for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        patch :update_title, params: { id: data_app_session1.id, title: "Update Title" }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        delete :destroy, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when an authenticated user hasn't accepted eula" do
      it "returns forbidden" do
        user.update!(eula_accepted: false)
        request.headers.merge!(auth_headers(user, workspace_id))
        delete :destroy, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when it is an authenticated user" do
      before do
        request.headers.merge!(auth_headers(user, workspace_id))
      end

      it "returns success and get chat message history" do
        delete :destroy, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:no_content)
      end

      it "returns success and get chat message history for member role" do
        workspace.workspace_users.first.update(role: member_role)
        delete :destroy, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:no_content)
      end

      it "returns success and get chat message history for viewer role" do
        workspace.workspace_users.first.update(role: viewer_role)
        delete :destroy, params: { id: data_app_session1.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
