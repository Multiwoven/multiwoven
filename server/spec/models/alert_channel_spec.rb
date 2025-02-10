# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertChannel, type: :model do
  describe "associations" do
    it { should belong_to(:alert) }
  end

  describe "#recipients" do
    let(:source) { create(:connector, connector_type: "source", connector_name: "Snowflake") }
    let(:destination) { create(:connector, connector_type: "destination") }
    let!(:catalog) { create(:catalog, connector: destination) }
    let(:sync) { create(:sync, name: "Sync alert test", source:, destination:) }
    let(:success_run) { create(:sync_run, sync:, status: :success, total_rows: 100, successful_rows: 100) }
    let(:success_alert) { create(:alert, alert_sync_success: true) }

    it "should return correct recipients for email platform" do
      alert_medium = create(:alert_medium)
      alert_channel = create(:alert_channel, alert_medium:, alert: success_alert,
                                             configuration: { extra_email_recipients: ["test@ais.com"] })
      success_alert.workspace.users.each { |u| u.update({ confirmed_at: Time.zone.now }) }
      expect(alert_channel.recipients).to eq(["test@ais.com"] + success_alert.workspace.users.pluck(:email))
    end

    it "should return correct recipients for slack platform" do
      alert_medium = create(:alert_medium, platform: "slack")
      alert_channel = create(:alert_channel, alert_medium:, alert: success_alert,
                                             configuration: { slack_email_alias: ["test@slackai.com"] })
      expect(alert_channel.recipients).to eq(["test@slackai.com"])
    end
  end
end
