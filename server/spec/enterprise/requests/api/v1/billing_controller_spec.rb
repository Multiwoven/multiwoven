# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::BillingController, type: :controller do
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:member) { create(:role, :member) }
  let(:viewer) { create(:role, :viewer) }

  before do
    user.update!(confirmed_at: Time.current)
    request.headers.merge!(auth_headers(user, workspace.id))
  end

  context "Admin" do
    describe "GET #usage" do
      it "returns http success" do
        get :usage
        expect(response).to have_http_status(:ok)

        subscription = workspace.organization.active_subscription
        response_data = JSON.parse(response.body)["data"]
        expect(response_data["type"]).to eq("billing-subscriptions")
        expect(response_data["attributes"]["organization_id"]).to eq(subscription.organization_id)
        expect(response_data["attributes"]["plan_id"]).to eq(subscription.plan_id)
        expect(response_data["attributes"]["status"]).to eq(subscription.status)
        expect(response_data["attributes"]["data_app_sessions"]).to eq(subscription.data_app_sessions)
        expect(response_data["attributes"]["feedback_count"]).to eq(subscription.feedback_count)
        expect(response_data["attributes"]["rows_synced"]).to eq(subscription.rows_synced)
        expect(response_data["attributes"]["addons_usage"]).to eq(subscription.addons_usage)

        plan_data = response_data["attributes"]["plan"]
        expect(plan_data["id"]).to eq(subscription.plan.id)
        expect(plan_data["name"]).to eq(subscription.plan.name)
        expect(plan_data["status"]).to eq(subscription.plan.status)
        expect(plan_data["amount"]).to eq(subscription.plan.amount)
        expect(plan_data["currency"]).to eq(subscription.plan.currency)
        expect(plan_data["interval"]).to eq(subscription.plan.interval)
        expect(plan_data["max_data_app_sessions"]).to eq(subscription.plan.max_data_app_sessions)
        expect(plan_data["max_feedback_count"]).to eq(subscription.plan.max_feedback_count)
        expect(plan_data["max_rows_synced"]).to eq(subscription.plan.max_rows_synced)
        expect(plan_data["addons"]).to eq(subscription.plan.addons)
      end
    end

    describe "GET #plans" do
      it "returns http success" do
        get :plans
        expect(response).to have_http_status(:ok)
        active_plans = Billing::Plan.active
        expect(JSON.parse(response.body)["data"].count).to eq(active_plans.count)

        JSON.parse(response.body)["data"].each_with_index do |plan_data, index|
          plan = active_plans[index]
          expect(plan_data["attributes"]["name"]).to eq(plan.name)
          expect(plan_data["attributes"]["amount"]).to eq(plan.amount)
        end
      end
    end
  end

  context "Member" do
    before do
      workspace_user = workspace.workspace_users.first
      workspace_user.role = member
      workspace_user.save!
    end

    describe "GET #usage" do
      it "returns unauthorized" do
        get :usage
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "GET #plans" do
      it "returns unauthorized" do
        get :plans
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context "Viewer" do
    before do
      workspace_user = workspace.workspace_users.first
      workspace_user.role = viewer
      workspace_user.save!
    end

    describe "GET #usage" do
      it "returns unauthorized" do
        get :usage
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "GET #plans" do
      it "returns unauthorized" do
        get :plans
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
