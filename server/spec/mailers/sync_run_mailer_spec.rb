# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncRunMailer, type: :mailer do
  describe "#status_email" do
    let(:source) do
      create(:connector, connector_type: "source", connector_name: "Snowflake")
    end
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, source:, destination:) }
    let(:sync_run) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "failed")
    end
    let(:sync_run_pending) do
      create(:sync_run, sync:, workspace: sync.workspace, source:, destination:, model: sync.model, status: "pending")
    end
    let(:recipient) { "test@example.com" }
    let(:mail) { SyncRunMailer.with(sync_run:, recipient:).status_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Sync failure")
      expect(mail.to).to eq([recipient])
      expect(mail.from).to eq(["ai2-mailer@squared.ai"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(sync.source.name)
      expect(mail.body.encoded).to match(sync.destination.name)
      host = ENV["UI_HOST"]
      url = "#{host}/activate/syncs/#{sync.id}/run/#{sync_run.id}"
      expect(mail.body.encoded).to match(url)
    end

    it "assigns @sync_run_url" do
      expect(mail.body.encoded).to match(sync_run.sync.id.to_s)
      expect(mail.body.encoded).to match(sync_run.id.to_s)
    end
  end
end
