# frozen_string_literal: true

# spec/requests/api/v1/workspace_users_spec.rb

require "swagger_helper"

RSpec.describe "API::V1::WorkspaceUsers", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  let(:workspace) { create(:workspace) }

  # Assuming the user is an admin
  before do
    create(:workspace_user, workspace:, user:, role: "admin")
  end

  path "/api/v1/workspaces/{workspace_id}/workspace_users" do
    post "Adds a user to a workspace" do
      tags "WorkspaceUsers"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :workspace_id, in: :path, type: :integer
      parameter name: :workspace_user, in: :body, schema: {
        type: :object,
        properties: {
          workspace_user: {
            type: :object,
            properties: {
              email: { type: :string },
              role: { type: :string }
            },
            required: %w[email role]
          }
        },
        required: ["workspace_user"]
      }

      response "201", "User added to workspace" do
        let(:Authorization) { headers["Authorization"] }
        let(:workspace_id) { workspace.id }
        let(:workspace_user) { { workspace_user: { email: "newuser@example.com", role: "member" } } }

        run_test!
      end
    end
  end

  path "/api/v1/workspaces/{workspace_id}/workspace_users/{id}" do
    put "Updates a user's role in a workspace" do
      tags "WorkspaceUsers"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :workspace_id, in: :path, type: :integer
      parameter name: :id, in: :path, type: :integer
      parameter name: :workspace_user, in: :body, schema: {
        type: :object,
        properties: {
          role: { type: :string }
        },
        required: ["role"]
      }

      response "200", "User role updated in workspace" do
        let(:Authorization) { headers["Authorization"] }
        let(:workspace_id) { workspace.id }
        let(:id) { workspace.workspace_users.first.id }
        let(:workspace_user) { { role: "member" } }

        run_test!
      end
    end

    delete "Removes a user from a workspace" do
      tags "WorkspaceUsers"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :workspace_id, in: :path, type: :integer
      parameter name: :id, in: :path, type: :integer

      response "204", "User removed from workspace" do
        let(:Authorization) { headers["Authorization"] }
        let(:workspace_id) { workspace.id }
        let(:id) { workspace.workspace_users.first.id }

        run_test!
      end
    end
  end
end
