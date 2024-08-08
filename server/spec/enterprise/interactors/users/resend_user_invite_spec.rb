# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::ResendUserInvite, type: :interactor do
  let(:workspace) { create(:workspace) }
  let(:user_invited_by) { create(:user) }
  let(:user) { create(:user, :invited, invited_by: user_invited_by) }
  let!(:workspace_user) { create(:workspace_user, user:, workspace:) }

  context "with valid params" do
    it "resends the invitation successfully" do
      original_invitation_sent_at = user.invitation_sent_at
      original_invitation_created_at = user.invitation_created_at

      result = described_class.call(
        workspace:,
        user_id: user.id
      )
      expect(result.success?).to eq(true)
      expect(result.user).to eq(user)

      user.reload

      expect(user.invitation_sent_at).not_to eq(original_invitation_sent_at)
      expect(user.invitation_created_at).not_to eq(original_invitation_created_at)
    end
  end

  context "with invalid user_id" do
    it "fails with an invalid user error" do
      result = described_class.call(
        workspace:,
        user_id: -1
      )
      expect(result.failure?).to eq(true)
      expect(result.message).to eq("Invalid User")
    end
  end

  context "when user is not invited" do
    let(:user) { create(:user, status: "active") }

    it "fails with an invalid user error" do
      result = described_class.call(
        workspace:,
        user_id: user.id
      )
      expect(result.failure?).to eq(true)
      expect(result.message).to eq("Invalid User")
    end
  end

  context "when invitation fails to send" do
    before do
      allow_any_instance_of(User).to receive(:deliver_invitation).and_raise(StandardError, "deliver_invitation failed")
    end

    it "fails with an invitation error" do
      result = described_class.call(
        workspace:,
        user_id: user.id
      )
      expect(result.failure?).to eq(true)
      expect(result.error).to eq("deliver_invitation failed")
    end
  end
end
