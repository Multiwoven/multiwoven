# frozen_string_literal: true

module AuditLogs
  class ExportAuditLog
    include Interactor
    def call
      # TODO: Add a background job for very large datasets.
      # Generating the CSV file synchronously can take too long,
      # potentially causing timeouts or degraded user experience.
      filtered_logs = Concerns::AuditLogFilter.new(context.audit_logs, context.audit_log_params).apply_filters
      context.csv_data = generate_csv(filtered_logs)
    end

    private

    # Method to generate CSV
    def generate_csv(audit_logs)
      CSV.generate(headers: true) do |csv|
        # Define the headers
        csv << %w[User_ID User_Name Action Resource_Type Resource_ID Workspace_ID Timestamp Resource_Link]
        # Add each audit log row to the CSV
        audit_logs.each do |log|
          csv << [
            log.user_id,
            log.user&.name,
            log.action,
            log.resource_type,
            log.resource_id,
            log.workspace_id,
            log.created_at,
            log.resource_link
          ]
        rescue StandardError => e
          Rails.logger.error("Error generating CSV: #{e.message}")
        end
      end
    end
  end
end
