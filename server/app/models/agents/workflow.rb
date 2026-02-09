# frozen_string_literal: true

module Agents
  class Workflow < ApplicationRecord
    has_paper_trail if: ->(_workflow) { false }, # Disable automatic versions
                    meta: {
                      version_number: :version_number,
                      associations: :associations_for_version
                    }

    def associations_for_version
      {
        components: components.map(&:attributes),
        edges: edges.map(&:attributes)
      }
    end

    def latest_published_version
      return nil if versions.empty?

      latest_published_version = versions.where(event: "published").reorder(version_number: :desc).first
      return nil if latest_published_version.nil?

      latest_workflow = latest_published_version.reify
      return nil if latest_workflow.nil?

      latest_workflow.association(:components).target = []
      latest_workflow.association(:edges).target = []
      latest_published_version.associations["components"].each do |component|
        latest_workflow.components.build(component)
      end
      latest_published_version.associations["edges"].each do |edge|
        latest_workflow.edges.build(edge)
      end
      latest_workflow
    end

    default_scope { order(updated_at: :desc) }

    belongs_to :workspace
    has_many :edges, dependent: :destroy
    has_many :components, dependent: :destroy
    has_many :workflow_runs, dependent: :destroy
    has_many :visual_components, as: :configurable, dependent: :destroy
    has_one :workflow_integration, dependent: :destroy

    enum status: { draft: 0, published: 1 }
    enum trigger_type: { website_chatbot: 0, chat_assistant: 1, scheduled: 2, api_trigger: 3, slack: 4 }

    validates :name, presence: true, uniqueness: { scope: :workspace_id, case_sensitive: false }
    validates :token, uniqueness: true, allow_nil: true

    store :configuration, coder: JSON

    before_save :generate_token_on_publish

    def build_dag
      ::Workflow::Dag.new(components, edges)
    end

    private

    def generate_token_on_publish
      self.token = SecureRandom.hex(16) if status_changed? && published?
    end

    def version_number_changed?
      saved_change_to_version_number?
    end
  end
end
