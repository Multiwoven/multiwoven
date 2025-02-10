# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncAlertMailer, type: :mailer do
  describe "#sync_success_email" do
    let(:now) { Time.zone.now }
    let(:sync_run_attrs) do
      {
        name: "Sync alert test",
        end_time: now,
        duration: 50,
        sync_id: 1,
        sync_run_id: 3,
        error: "",
        recipients: ["test@ais.com"]
      }
    end
    let(:mail) { SyncAlertMailer.with(sync_run_attrs).sync_success_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Sync run success")
      expect(mail.to).to eq(["test@ais.com"])
      expect(mail.from).to eq(["ai2-mailer@squared.ai"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Sync alert test")
      host = ENV["UI_HOST"]
      url = "#{host}/activate/syncs/1/run/3"
      expect(mail.body.encoded).to match(url)
    end
  end

  describe "#sync_failure_email" do
    let(:now) { Time.zone.now }
    let(:sync_run_attrs) do
      {
        name: "Sync alert test",
        end_time: now,
        duration: 50,
        sync_id: 1,
        sync_run_id: 3,
        error: "Sync failure error",
        recipients: ["test@ais.com"]
      }
    end
    let(:mail) { SyncAlertMailer.with(sync_run_attrs).sync_failure_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Sync run failed")
      expect(mail.to).to eq(["test@ais.com"])
      expect(mail.from).to eq(["ai2-mailer@squared.ai"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Sync alert test")
      expect(mail.body.encoded).to match("Sync failure error")
      host = ENV["UI_HOST"]
      url = "#{host}/activate/syncs/1/run/3"
      expect(mail.body.encoded).to match(url)
    end
  end

  describe "#sync_row_failure_email" do
    let(:now) { Time.zone.now }
    let(:sync_run_attrs) do
      {
        name: "Sync alert test",
        end_time: now,
        duration: 50,
        sync_id: 1,
        sync_run_id: 3,
        error: "Sync row failure error",
        recipients: ["test@ais.com"]
      }
    end
    let(:mail) { SyncAlertMailer.with(sync_run_attrs).sync_row_failure_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Sync completed with failed rows")
      expect(mail.to).to eq(["test@ais.com"])
      expect(mail.from).to eq(["ai2-mailer@squared.ai"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Sync alert test")
      expect(mail.body.encoded).to match("Sync row failure error")
      host = ENV["UI_HOST"]
      url = "#{host}/activate/syncs/1/run/3"
      expect(mail.body.encoded).to match(url)
    end
  end
end
