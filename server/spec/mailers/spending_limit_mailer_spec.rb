# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpendingLimitMailer, type: :mailer do
  describe "#threshold_alert_email" do
    let(:alert_attrs) do
      {
        recipients: ["test@ais.com"],
        limit_id: 1,
        limit_name: "Sales budget",
        workspace_name: "Acme",
        percentage: 80,
        period: "monthly",
        resets_at: Time.utc(2026, 10, 1),
        spent_cost: BigDecimal("80.0"),
        cost_limit: BigDecimal("100.0"),
        spent_tokens: 0,
        token_limit: nil,
        action_on_exhaust: "block"
      }
    end
    let(:mail) { described_class.with(alert_attrs).threshold_alert_email }

    it "renders the headers" do
      expect(mail.subject).to eq('Spend limit "Sales budget" reached 80%')
      expect(mail.to).to eq(["test@ais.com"])
    end

    it "sends from the configured address like the other mailers" do
      expect(mail.from).to eq([Mail::Address.new(Rails.configuration.x.mail_from).address])
    end

    it "shows when the period resets" do
      expect(mail.body.encoded).to match("Period Resets")
      expect(mail.body.encoded).to match("Oct 01, 2026 12:00 AM UTC")
    end

    it "renders without a reset time instead of raising" do
      mail = described_class.with(alert_attrs.merge(resets_at: nil)).threshold_alert_email

      expect(mail.body.encoded).to match("Sales budget")
      expect(mail.body.encoded).not_to match("Period Resets")
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Sales budget")
      expect(mail.body.encoded).to match("Spend Limit at 80%")
      expect(mail.body.encoded).to match("Acme")
    end

    it "goes to every recipient it is given" do
      mail = described_class.with(alert_attrs.merge(recipients: %w[one@ais.com two@ais.com]))
                            .threshold_alert_email

      expect(mail.to).to eq(%w[one@ais.com two@ais.com])
    end

    it "shows the spend against a cost limit and leaves the token row out" do
      expect(mail.body.encoded).to match("Spent")
      expect(mail.body.encoded).not_to match("Tokens")
    end

    it "shows the token row for a limit measured in tokens" do
      mail = described_class.with(alert_attrs.merge(cost_limit: nil, token_limit: 10_000, spent_tokens: 9000))
                            .threshold_alert_email

      expect(mail.body.encoded).to match("Tokens")
      expect(mail.body.encoded).to match("10,000")
    end
  end
end
