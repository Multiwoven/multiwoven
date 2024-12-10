# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLogs::ExportAuditLog, type: :interactor do
  describe ".call" do
    let(:workspace) { create(:workspace) }
    let!(:workspace_id) { workspace.id }
    let(:user) { workspace.workspace_users.first.user }
    let!(:audit_logs) do
      AuditLog.where(workspace:, user:).tap do
        create(:audit_log, resource_type: "Test", workspace:, user:)
        create(:audit_log, resource_type: "Test", resource: "Sync_Test", created_at: 1.day.ago,
                           updated_at: 1.day.ago, workspace:, user:)
        create(:audit_log, resource: "Sync_Test", created_at: 1.day.ago, updated_at: 1.day.ago, workspace:, user:)
        create(:audit_log, resource_type: "Test", created_at: 2.days.ago, updated_at: 2.days.ago, workspace:, user:)
        create(:audit_log, created_at: 3.days.ago, updated_at: 3.days.ago, workspace:, user:)
      end
    end

    let(:mock_context) do
      {
        audit_log_params: {
          start_date: (Time.current - 2.days).strftime("%Y-%m-%d"),
          end_date: (Time.current + 1.day).strftime("%Y-%m-%d"),
          user_id: audit_logs.first.user_id,
          resource_type: audit_logs.first.resource_type,
          resource: audit_logs.first.resource
        },
        audit_logs:
      }
    end

    let(:mock_no_filter) do
      {
        audit_log_params: {},
        audit_logs:
      }
    end

    let(:empty_context) do
      {
        audit_log_params: {},
        audit_logs: AuditLog.none
      }
    end

    context "when the audit log is exported successfully" do
      it "return exported csv" do
        result = described_class.call(mock_context)
        expect(result).to be_a_success
        expect(result.csv_data).to include("User_ID")
        expect(result.csv_data).to include("User_Name")
        expect(result.csv_data).to include("Action")
        expect(result.csv_data).to include("Resource_Type")
        expect(result.csv_data).to include("Resource_ID")
        expect(result.csv_data).to include("Workspace_ID")
        expect(result.csv_data).to include("Timestamp")
        expect(result.csv_data).to include("Resource_Link")
        expect(result.csv_data).to include("")
        expect(result.csv_data).to include(audit_logs.first.created_at.to_s)
      end
    end

    context "when the audit log has an empty user_id" do
      it "return exported csv" do
        audit_logs.update(user_id: nil)
        result = described_class.call(mock_no_filter)
        expect(result).to be_a_success
        expect(result.csv_data).to include("User_ID")
        expect(result.csv_data).to include("User_Name")
        expect(result.csv_data).to include("Action")
        expect(result.csv_data).to include("Resource_Type")
        expect(result.csv_data).to include("Resource_ID")
        expect(result.csv_data).to include("Workspace_ID")
        expect(result.csv_data).to include("Timestamp")
        expect(result.csv_data).to include("Resource_Link")
        expect(result.csv_data).to include("")
        expect(result.csv_data).to include(audit_logs.last.created_at.to_s)
      end
    end

    context "when the audit log is empty" do
      it "returns empty csv" do
        result = described_class.call(empty_context)
        expect(result).to be_a_success
        expect(result.csv_data).to include("User_ID")
        expect(result.csv_data).to include("User_Name")
        expect(result.csv_data).to include("Action")
        expect(result.csv_data).to include("Resource_Type")
        expect(result.csv_data).to include("Resource_ID")
        expect(result.csv_data).to include("Workspace_ID")
        expect(result.csv_data).to include("Timestamp")
        expect(result.csv_data).to include("Resource_Link")
        expect(result.csv_data).to include("")
      end
    end
  end
end
