# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbedOrigins::Registry do
  describe ".propagation_meta" do
    it "returns the refresh interval and a human-readable message" do
      meta = described_class.propagation_meta
      expect(meta[:refresh_interval_seconds]).to eq(described_class::REFRESH_INTERVAL_SECONDS)
      expect(meta[:message]).to include(described_class::REFRESH_INTERVAL_SECONDS.to_s)
    end
  end

  describe ".normalize_origin" do
    it "returns nil for blank input" do
      expect(described_class.normalize_origin(nil)).to be_nil
      expect(described_class.normalize_origin("")).to be_nil
      expect(described_class.normalize_origin("   ")).to be_nil
    end

    it "strips a trailing slash" do
      expect(described_class.normalize_origin("https://customer.com/")).to eq("https://customer.com")
    end

    it "strips surrounding whitespace" do
      expect(described_class.normalize_origin(" https://customer.com ")).to eq("https://customer.com")
    end

    it "downcases scheme and host but keeps port" do
      expect(described_class.normalize_origin("HTTPS://Customer.COM:8443")).to eq("https://customer.com:8443")
    end

    it "leaves already-canonical origins untouched" do
      expect(described_class.normalize_origin("https://customer.com")).to eq("https://customer.com")
    end
  end

  describe "snapshot" do
    let(:organization) { create(:organization) }
    let(:workspace)    { create(:workspace, organization:) }
    let(:other_ws)     { create(:workspace, organization:) }
    let(:other_org)    { create(:organization) }
    let(:other_org_ws) { create(:workspace, organization: other_org) }
    let(:user)         { create(:user) }

    before { described_class.refresh! }

    it "returns the union of workspace-scoped + org-wide origins" do
      create(:user_embed_origin,
             created_by_user: user, origin: "https://ws.com",
             organization:, workspace:)
      create(:user_embed_origin,
             created_by_user: user, origin: "https://orgwide.com",
             organization:, workspace: nil)
      described_class.refresh!

      expect(described_class.allowlist_for(workspace.id)).to eq(Set["https://ws.com", "https://orgwide.com"])
    end

    it "isolates workspaces within the same org" do
      create(:user_embed_origin,
             created_by_user: user, origin: "https://ws1.com",
             organization:, workspace:)
      create(:user_embed_origin,
             created_by_user: user, origin: "https://ws2.com",
             organization:, workspace: other_ws)
      described_class.refresh!

      expect(described_class.allowlist_for(workspace.id)).to contain_exactly("https://ws1.com")
      expect(described_class.allowlist_for(other_ws.id)).to contain_exactly("https://ws2.com")
    end

    it "isolates orgs — org A's org-wide entry never leaks to org B's workspace" do
      create(:user_embed_origin,
             created_by_user: user, origin: "https://orgA.com",
             organization:, workspace: nil)
      described_class.refresh!

      expect(described_class.allowlist_for(other_org_ws.id)).to be_empty
    end

    it "returns an empty set for a workspace with no origins" do
      described_class.refresh!
      expect(described_class.allowlist_for(workspace.id)).to be_empty
    end

    it "normalizes stored origins so trailing slashes match" do
      # `save(validate: false)` skips before_validation → normalize_origin does
      # not run, so the trailing slash persists in the DB. This exercises the
      # Registry's own defensive normalization on load.
      record = UserEmbedOrigin.new(
        origin: "https://slashy.com/",
        created_by_user: user,
        organization:,
        workspace:
      )
      record.save(validate: false)
      described_class.refresh!

      expect(described_class.allowlist_for(workspace.id)).to include("https://slashy.com")
    end
  end

  describe "app-to-workspace lookups" do
    let!(:workspace) { create(:workspace) }
    let!(:data_app)  { create(:data_app, workspace:, status: :active) }

    before { described_class.refresh! }

    it ".workspace_id_for_data_app resolves numeric id" do
      expect(described_class.workspace_id_for_data_app(data_app.id)).to eq(workspace.id)
    end

    it ".workspace_id_for_data_app resolves string id" do
      expect(described_class.workspace_id_for_data_app(data_app.id.to_s)).to eq(workspace.id)
    end

    it "returns nil for an unknown data_app_id" do
      expect(described_class.workspace_id_for_data_app(9_999_999)).to be_nil
    end

    it "excludes non-active data apps from the map" do
      draft = create(:data_app, workspace:, status: :draft)
      inactive = create(:data_app, workspace:, status: :inactive)
      described_class.refresh!

      expect(described_class.workspace_id_for_data_app(draft.id)).to be_nil
      expect(described_class.workspace_id_for_data_app(inactive.id)).to be_nil
    end
  end

  describe "data_app map — workflow-linked DataApps merged in" do
    let!(:workspace) { create(:workspace) }
    let!(:workflow)  { create(:workflow, workspace:, status: :published) }
    # The DataApp backing the workflow's chatbot interface, wired via
    # VisualComponent. Its own status may be :draft — inclusion is driven by
    # the workflow's :published state, not the DataApp's own status.
    let!(:workflow_data_app) do
      create(:data_app, workspace:, status: :draft).tap do |da|
        create(:visual_component, data_app: da, configurable: workflow, workspace:)
      end
    end

    before { described_class.refresh! }

    it "includes a draft DataApp that backs a published workflow" do
      expect(described_class.workspace_id_for_data_app(workflow_data_app.id)).to eq(workspace.id)
    end

    it "excludes DataApps whose workflow is still draft" do
      draft_workflow = create(:workflow, workspace:, status: :draft, name: "Draft Workflow")
      orphan_data_app = create(:data_app, workspace:, status: :draft)
      create(:visual_component, data_app: orphan_data_app, configurable: draft_workflow, workspace:)
      described_class.refresh!

      expect(described_class.workspace_id_for_data_app(orphan_data_app.id)).to be_nil
    end

    it "still includes standalone active DataApps (no workflow attached)" do
      standalone = create(:data_app, workspace:, status: :active)
      described_class.refresh!

      expect(described_class.workspace_id_for_data_app(standalone.id)).to eq(workspace.id)
    end
  end

  describe "agentic-app-to-workspace lookups (UUID PK)" do
    let!(:workspace) { create(:workspace) }
    let!(:published_app) { create(:agentic_coding_app, workspace:, status: :published) }

    before { described_class.refresh! }

    it ".workspace_id_for_agentic_app resolves a UUID string" do
      expect(described_class.workspace_id_for_agentic_app(published_app.id)).to eq(workspace.id)
    end

    it "excludes draft agentic apps from the map" do
      draft_app = create(:agentic_coding_app, workspace:, status: :draft)
      described_class.refresh!

      expect(described_class.workspace_id_for_agentic_app(draft_app.id)).to be_nil
    end

    it "returns nil for an unknown UUID" do
      expect(described_class.workspace_id_for_agentic_app("00000000-0000-0000-0000-000000000000")).to be_nil
    end
  end
end
