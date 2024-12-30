# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourceLinkBuilder, type: :controller do
  include ResourceLinkBuilder
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.workspace_users.first.user }
  let(:connector) { create(:connector, workspace:, connector_type: "source") }
  let(:destination) { create(:connector, workspace:) }
  let(:model) { create(:model, workspace:, connector:) }
  let(:sync) do
    build(:sync, workspace:, source: connector, destination:, model:, cursor_field: "timestamp",
                 current_cursor_field: "2022-01-01")
  end
  let!(:data_app) { create(:data_app, workspace:) }
  let!(:visual_component) { create(:visual_component, data_app:, workspace:) }
  let(:session) { create(:data_app_session, data_app:, session_id: "session_1") }
  let!(:feedback) { create(:feedback, visual_component:) }

  before do
    create(:catalog, connector:)
    create(:catalog, connector: destination)
  end

  describe "#build_link!" do
    context "with valid params for connectors_link" do
      it "creates a connectors link for AI Model" do
        connector.id = 123
        connector.connector_category = "AI Model"
        result = build_link!(
          resource_type: "Catalog",
          resource: connector,
          resource_id: connector.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/setup/sources/AIML%20Sources/#{connector.id}")
      end
    end

    context "with valid params for connectors_link" do
      it "creates a connectors link for Data Source" do
        connector.id = 123
        result = build_link!(
          resource_type: "Connector",
          resource: connector,
          resource_id: connector.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/setup/sources/Data%20Sources/#{connector.id}")
      end
    end

    context "with valid params for connectors_link" do
      it "creates a connectors link for Destinations" do
        connector.id = 123
        result = build_link!(
          resource_type: "Connector",
          resource: destination,
          resource_id: destination.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/setup/destinations/#{destination.id}")
      end
    end

    context "with valid params for models_link" do
      it "creates a model link for ai_ml query type models" do
        model.query_type = "ai_ml"
        result = build_link!(
          resource_type: "Model",
          resource: model,
          resource_id: model.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/define/models/ai/#{model.id}")
      end
    end

    context "with valid params for models_link" do
      it "creates a model link for raw_sql query type models" do
        result = build_link!(
          resource_type: "Model",
          resource: model,
          resource_id: model.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/define/models/#{model.id}")
      end
    end

    context "with valid params for syncs_link" do
      it "creates a sync link for sync" do
        result = build_link!(
          resource_type: "Sync",
          resource_id: sync.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/activate/syncs/#{sync.id}")
      end
    end

    context "with valid params for data_apps_link" do
      it "creates a data app link for data app" do
        result = build_link!(
          resource_type: "Data_app",
          resource_id: data_app.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/data-apps/list/#{data_app.id}")
      end
    end

    context "with valid params for members_link" do
      it "creates a member link for user" do
        result = build_link!(
          resource_type: "User"
        )
        expect(result).to_not be_nil
        expect(result).to eq("/settings/members")
      end
    end

    context "with valid params for reports_link" do
      it "creates a report link for feedback" do
        result = build_link!(
          resource_type: "Feedback",
          resource_id: feedback.id
        )
        expect(result).to_not be_nil
        expect(result).to eq("/reports/#{feedback.id}")
      end
    end

    context "when error arises" do
      it "return nil" do
        result = build_link!(
          resource_type: "Catalog"
        )
        expect(result).to be_nil
      end
    end
  end
end
