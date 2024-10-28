# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLogger, type: :controller do
  include AuditLogger
  let(:workspace) { create(:workspace) }
  let(:user) { workspace.users.first }

  describe "#audit!" do
    context "when creating an audit log" do
      it "creates an audit log" do
        payload = ActionController::Parameters.new(key: "value")
        expect do
          audit!(
            user:,
            action: "create",
            resource_type: "TestController",
            resource_id: nil,
            resource: nil,
            workspace:,
            payload:
          )
        end.to change(AuditLog, :count).by(1)

        audit_log = AuditLog.last
        expect(audit_log.user_id).to eq(user.id)
        expect(audit_log.action).to eq("create")
        expect(audit_log.resource_type).to eq("TestController")
        expect(audit_log.resource_id).to eq(nil)
        expect(audit_log.resource).to eq(nil)
        expect(audit_log.workspace.id).to eq(workspace.id)
        expect(audit_log.metadata).to eq(payload.to_unsafe_h)
        expect(audit_log.created_at).not_to be_nil
        expect(audit_log.updated_at).not_to be_nil
      end
    end

    context "when there is an error during audit log creation" do
      it "log error" do
        expect { audit! }.to raise_error(NameError)
      end
    end
  end
end
