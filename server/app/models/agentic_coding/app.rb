# frozen_string_literal: true

module AgenticCoding
  class App < ApplicationRecord
    belongs_to :workspace
    belongs_to :user
    belongs_to :template, class_name: "AgenticCoding::Template", optional: true, inverse_of: :apps
    belongs_to :source_app, class_name: "AgenticCoding::App", optional: true

    has_many :sessions, class_name: "AgenticCoding::Session", dependent: :destroy, inverse_of: :agentic_coding_app
    has_many :prompts, class_name: "AgenticCoding::Prompt", dependent: :destroy, inverse_of: :agentic_coding_app
    has_many :deployments, class_name: "AgenticCoding::Deployment", dependent: :destroy, inverse_of: :agentic_coding_app
    has_many :clones, class_name: "AgenticCoding::App",
                      foreign_key: :source_app_id,
                      dependent: :nullify,
                      inverse_of: :source_app
    has_many :app_resources, class_name: "AgenticCoding::AppResource",
                             dependent: :destroy,
                             inverse_of: :agentic_coding_app

    has_many :visitors, class_name: "AgenticCoding::AppVisitor", dependent: :destroy, inverse_of: :app

    enum status: {
      draft: 0,
      published: 1,
      archived: 2
    }

    validates :name, presence: true
    validates :status, presence: true

    before_destroy :cleanup_database

    def database
      return nil unless defined?(AgenticCoding::DatabaseProvisioner)

      resource_type = AgenticCoding::DatabaseProvisioner.resource_type
      app_resources.where.not(status: "deleted").find_by(resource_type:)
    end
    alias neon_database database

    def s3_storage
      app_resources.where.not(status: "deleted").find_by(resource_type: "s3_storage")
    end

    private

    def cleanup_database
      return unless defined?(AgenticCoding::DatabaseProvisioner)

      AgenticCoding::DatabaseProvisioner.delete_for_app(self)
    rescue StandardError => e
      Rails.logger.warn("[AgenticCoding::App] Database cleanup failed for app #{id}: #{e.message}")
    end
  end
end
