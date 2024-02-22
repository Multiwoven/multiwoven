# frozen_string_literal: true

module Middlewares
  class LoggingMiddleware
    def initialize(app_name)
      @app_name = app_name
    end

    def call(metadata)
      entity_name = name_from(metadata)
      entity_type = type_from(metadata)
      Temporal.logger.info("[#{app_name}]: Started #{entity_name} #{entity_type}", metadata: metadata.to_h)

      yield

      Temporal.logger.info("[#{app_name}]: Finished #{entity_name} #{entity_type}", metadata: metadata.to_h)
    rescue StandardError => e
      error_tracking = "Error: #{e.message}, Stack trace: #{e.backtrace.join("\n")}"
      Temporal.logger.error(
        "[#{app_name}]: Error #{entity_name} #{entity_type} #{error_tracking}",
        metadata: metadata.to_h
      )

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
