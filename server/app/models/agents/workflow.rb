# frozen_string_literal: true

module Agents
  class Workflow < ApplicationRecord
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

    def accessible_by?(user)
      return true unless access_control_enabled

      allowed_role_ids, allowed_users = extract_access_control_lists

      # If both lists are empty, no restrictions = accessible to all
      return true if allowed_role_ids.empty? && allowed_users.empty?

      role_allowed?(user, allowed_role_ids) || user_allowed?(user, allowed_users)
    end

    private

    def extract_access_control_lists
      access_control_hash = access_control || {}
      allowed_role_ids = Array(access_control_hash["allowed_role_ids"]).filter_map do |id|
        Integer(id, exception: false)
      end
      allowed_users = Array(access_control_hash["allowed_users"]).compact
      [allowed_role_ids, allowed_users]
    end

    def role_allowed?(user, allowed_role_ids)
      return false if allowed_role_ids.empty?

      workspace_user = workspace.workspace_users.find_by(user:)
      user_role_id = workspace_user&.role_id
      user_role_id.present? && allowed_role_ids.include?(user_role_id)
    end

    def user_allowed?(user, allowed_users)
      return false if user.nil? || allowed_users.empty?

      allowed_users.include?(user.email)
    end

    def generate_token_on_publish
      self.token = SecureRandom.hex(16) if status_changed? && published?
    end
  end
end
