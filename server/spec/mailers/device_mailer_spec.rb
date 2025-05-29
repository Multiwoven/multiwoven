# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  describe "invitation_instructions" do
    let(:workspace) { create(:workspace) }
    let(:inviter) { create(:user, name: "Inviter Name") }
    let(:resource) { create(:user, :invited, name: nil, invited_by: inviter) }
    let!(:workspace_user) { create(:workspace_user, user: inviter, workspace:) }
    let!(:workspace_user_by) { create(:workspace_user, user: resource, workspace:) }
    let!(:token) { resource.raw_invitation_token }
    let(:opts) { { workspace:, role: nil } }
    let(:mail) { described_class.invitation_instructions(resource, token, opts).deliver_now }
    before do
      allow(ENV).to receive(:[]).with("UI_HOST").and_return("https://example.com")
    end
    it "renders the subject" do
      expect(mail.subject).to eq("Invitation instructions")
    end

    it "renders the receiver email" do
      expect(mail.to).to eq([resource.email])
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["ai2-mailer@squared.ai"])
    end

    it "contains the inviter's name and workspace name in the body" do
      expect(mail.body.encoded)
        .to match("#{inviter.name} has invited you to use AI Squared with them, " \
          "in a company called #{workspace.organization.name}")
    end

    it "contains the correct sign-up link" do
      query_params = [
        ["invitation_token", token],
        ["invited", true],
        ["invited_by", inviter.name],
        ["invited_user", resource.email],
        ["organization_name", workspace.organization.name],
        ["workspace_id", workspace.id],
        ["workspace_name", workspace.name]
      ]
      custom_url = "https://example.com/sign-up?#{URI.encode_www_form(query_params)}"

      doc = Nokogiri::HTML(mail.body.encoded)
      link = doc.at_css("a")["href"]

      expect(link).to eq(custom_url)
    end

    it "contains the invitation due date if present" do
      due_date = I18n.l(resource.invitation_due_at,
                        format: :'devise.mailer.invitation_instructions.accept_until_format')
      expect(mail.body.encoded).to match(I18n.t("devise.mailer.invitation_instructions.accept_until",
                                                due_date:))
    end
  end

  describe "reset_password_instructions" do
    let(:user) { create(:user) }
    let(:token) { "testtoken" }
    let(:mail) { DeviseMailer.reset_password_instructions(user, token) }

    before do
      allow(ENV).to receive(:[]).with("UI_HOST").and_return("https://example.com")
      allow(ENV).to receive(:[]).with("USER_EMAIL_VERIFICATION").and_return("true")
      user.update(reset_password_sent_at: Time.current)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Reset password instructions")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Reset your password")
      expect(mail.body.encoded).to match("A password change has been requested for your account.")
      doc = Nokogiri::HTML(mail.body.encoded)
      link = doc.at_css("a")["href"]
      reset_url = "https://example.com/reset-password?reset_password_token=testtoken"
      expect(link).to eq(reset_url)
    end
  end

  describe "password_change" do
    let(:user) { create(:user) }
    let(:mail) { DeviseMailer.password_change(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Password Changed")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Your password has been changed")
    end
  end

  describe "confirmation_instructions" do
    let(:user) { create(:user) }
    let(:token) { "testtoken" }
    let(:mail) { DeviseMailer.confirmation_instructions(user, token) }

    before do
      allow(ENV).to receive(:[]).with("UI_HOST").and_return("https://example.com")
      allow(ENV).to receive(:[]).with("USER_EMAIL_VERIFICATION").and_return("true")
      user.update(confirmation_sent_at: Time.current)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Confirmation instructions")
      expect(mail.to).to eq([user.email])
    end

    it "renders the body" do
      query_params = [
        ["confirmation_token", token],
        ["email", user.email]
      ]
      expect(mail.body.encoded).to match("Verify your email")
      expect(mail.body.encoded)
        .to match("To complete signup and start using AI Squared, just click the verification button below.")
      doc = Nokogiri::HTML(mail.body.encoded)
      link = doc.at_css("a")["href"]
      reset_url = "https://example.com/verify-user?#{URI.encode_www_form(query_params)}"
      expect(link).to eq(reset_url)
    end
  end
end
