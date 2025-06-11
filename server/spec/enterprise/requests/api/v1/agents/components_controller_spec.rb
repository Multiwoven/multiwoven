# frozen_string_literal: true

require "rails_helper"

RSpec.describe Enterprise::Api::V1::Agents::ComponentsController, type: :controller do
  let(:workspace) { create(:workspace) }
  let!(:workspace_id) { workspace.id }
  let(:user) { workspace.workspace_users.first.user }
  let(:member_role) { create(:role, :member) }
  let(:viewer_role) { create(:role, :viewer) }
  let(:expected_component_ids) { %w[chat_input chat_output prompt_template data_storage vector_store llm_model] }

  before do
    user.update!(confirmed_at: Time.current)
  end

  describe "GET /enterprise/api/v1/agents/components" do
    context "when it is an unauthenticated user" do
      it "returns unauthorized" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when it is an authenticated user" do
      before do
        request.headers.merge!(auth_headers(user, workspace_id))
        workspace.workspace_users.first.update(role: member_role)
      end

      context "when component list is successful" do
        it "returns success response with schemas" do
          get :index
          expect(response).to have_http_status(:ok)

          response_data = JSON.parse(response.body)["schemas"]
          expect(response_data.size).to eq(6)

          # Validate component IDs
          response_ids = response_data.map { |component| component["type"] }
          expect(response_ids).to match_array(expected_component_ids)
        end
      end

      context "when component list fails" do
        before do
          context = Interactor::Context.new
          context.error = "Failed to load components"
          allow(context).to receive(:success?).and_return(false)
          allow(Agents::ComponentList).to receive(:call).and_return(context)
        end

        it "returns error response" do
          get :index
          expect(response).to have_http_status(:unprocessable_content)
          expect(JSON.parse(response.body)).to eq({
                                                    "errors" => [{
                                                      "detail" => "Components Fetch Failed: Failed to load components",
                                                      "source" => "Failed to load components",
                                                      "status" => 422,
                                                      "title" => "Error"
                                                    }]
                                                  })
        end
      end
    end
  end
end
