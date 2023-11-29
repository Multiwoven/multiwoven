# frozen_string_literal: true

# spec/requests/api/v1/workspaces_spec.rb

require "swagger_helper"

RSpec.describe "API::V1::Workspaces", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  # Create a workspace and associate it with the user
  let(:workspace) do
    ws = create(:workspace)
    create(:workspace_user, workspace: ws, user:, role: "admin")
    ws
  end

  path "/api/v1/workspaces" do
    get "Lists all workspaces" do
      tags "Workspaces"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "Workspaces retrieved" do
        let(:Authorization) { headers["Authorization"] }

        before { create_list(:workspace, 5) }

        run_test!
      end
    end

    post "Creates a workspace" do
      tags "Workspaces"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :workspace, in: :body, schema: {
        type: :object,
        properties: {
          workspace: {
            type: :object,
            properties: {
              name: { type: :string }
            },
            required: ["name"]
          }
        },
        required: ["name"]
      }

      response "201", "Workspace created" do
        let(:Authorization) { headers["Authorization"] }
        let(:workspace) { { name: "New workspace" } }

        run_test!
      end
    end
  end

  path "/api/v1/workspaces/{id}" do
    put "Updates a workspace" do
      tags "Workspaces"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :id, in: :path, type: :integer
      parameter name: :workspace, in: :body, schema: {
        type: :object,
        properties: {
          workspace: {
            type: :object,
            properties: {
              name: { type: :string }
            }
          }
        }
      }

      response "200", "Workspace updated" do
        let(:Authorization) { headers["Authorization"] }
        let(:id) { workspace.id }
        let(:update_workspace_payload) { { name: "Updated workspace name" } } # renamed variable

        run_test!
      end
    end

    delete "Deletes a workspace" do
      tags "Workspaces"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :id, in: :path, type: :integer

      response "204", "Workspace deleted" do
        let(:Authorization) { headers["Authorization"] }
        let(:id) { workspace.id } # using existing 'let!(:workspace)'

        run_test!
      end
    end
  end
end
