# frozen_string_literal: true

module AgenticCoding
  class Prompt < ApplicationRecord
    belongs_to :agentic_coding_app, class_name: "AgenticCoding::App", inverse_of: :prompts
    belongs_to :agentic_coding_session, class_name: "AgenticCoding::Session", inverse_of: :prompts

    enum role: { user: 0, assistant: 1 }
    enum status: {
      queued: 0,
      running: 1,
      completed: 2,
      failed: 3
    }

    validates :content, :role, :status, presence: true
    validate :validate_context_structure

    CONTEXT_SCHEMA = JSONSchemer.schema({
                                          "type" => "object",
                                          "properties" => {
                                            "connectors" => { "type" => "array", "items" => { "type" => "string" } },
                                            "workflows" => { "type" => "array", "items" => { "type" => "string" } },
                                            "apis" => { "type" => "array", "items" => { "type" => "string" } }
                                          },
                                          "additionalProperties" => false
                                        })

    private

    def validate_context_structure
      return if context.blank?

      CONTEXT_SCHEMA.validate(context).each do |error|
        pointer = error["data_pointer"]
        type = error["type"]
        errors.add(:context, "property #{pointer} is invalid: expected #{type}")
      end
    end
  end
end
