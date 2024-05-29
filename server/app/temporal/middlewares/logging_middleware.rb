# frozen_string_literal: true

module Middlewares
  class LoggingMiddleware
    def initialize(app_name)
      @app_name = app_name
    end

    def call(metadata)
      entity_name = name_from(metadata)
      entity_type = type_from(metadata)
      Rails.logger.info(
        message: "[#{app_name}]: Started #{entity_name} #{entity_type}",
        metadata: metadata.to_h
      )

      yield

      Rails.logger.info(message: "[#{app_name}]: Finished #{entity_name} #{entity_type}", metadata: metadata.to_h)
    rescue StandardError => e
      Utils::ExceptionReporter.report(e)
      error_tracking = "Error: #{e.message}, Stack trace: #{e.backtrace.join("\n")}"
      Rails.logger.error("[#{app_name}]: Error #{entity_name} #{entity_type} #{error_tracking}")
      raise
    end

    private

    attr_reader :app_name

    def type_from(metadata)
      if metadata.activity?
        "activity"
      elsif metadata.workflow_task?
        "task"
      end
    end

    def name_from(metadata)
      if metadata.activity?
        metadata.name
      elsif metadata.workflow_task?
        metadata.workflow_name
      end
    end
  end
end
