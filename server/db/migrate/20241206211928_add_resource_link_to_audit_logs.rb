class AddResourceLinkToAuditLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :audit_logs, :resource_link, :string
  end
end
