# frozen_string_literal: true

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  api_key    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Workspace < ApplicationRecord
  has_many :workspace_users, dependent: :nullify
  has_many :users, through: :workspace_users
  has_many :connectors, dependent: :nullify
  has_many :models, dependent: :nullify
  has_many :catalogs, dependent: :nullify
  has_many :syncs, dependent: :nullify
  has_many :sync_runs, dependent: :nullify
  has_many :data_apps, dependent: :nullify
  has_many :data_app_sessions, dependent: :nullify
  has_many :audit_logs, dependent: :nullify
  has_many :custom_visual_component_files, dependent: :nullify
  has_many :alerts, dependent: :nullify
  has_many :message_feedbacks, dependent: :nullify
  has_many :chat_messages, dependent: :nullify
  has_many :workflows, class_name: "Agents::Workflow", dependent: :destroy
  has_many :workflow_runs, class_name: "Agents::WorkflowRun", dependent: :destroy
  has_many :workflow_logs, class_name: "Agents::WorkflowLog", dependent: :nullify
  has_many :workflow_integrations, class_name: "Agents::WorkflowIntegration", dependent: :nullify
<<<<<<< HEAD
=======
  has_many :hosted_data_stores, dependent: :nullify
  has_many :knowledge_bases, class_name: "Agents::KnowledgeBase", dependent: :nullify
  has_many :tools, class_name: "Agents::Tool", dependent: :destroy
  has_many :llm_routing_logs, dependent: :destroy
  has_many :llm_usage_logs, dependent: :destroy
>>>>>>> 6f1a6fb16 (chore(CE): Add LLM Usage Log (#1649))

  belongs_to :organization
  has_many :sso_configurations, through: :organization
  has_one_attached :file

  STATUS_ACTIVE = "active"
  STATUS_INACTIVE = "inactive"
  STATUS_PENDING = "pending"

  validates :name, presence: true
  validates :slug, presence: true
  validates :status, inclusion: { in: [STATUS_ACTIVE, STATUS_INACTIVE, STATUS_PENDING] }

  before_validation :generate_slug_and_status, on: :create
  before_update :update_slug, if: :name_changed?

  def active_alerts?
    alerts.present?
  end

  def verified_admin_user_emails
    admin_users.where.not(users: { confirmed_at: nil }).pluck(:email)
  end

  private

  def admin_users
    workspace_users.admins.joins(:user)
  end

  def generate_slug_and_status
    self.slug ||= name.parameterize if name
    self.api_key ||= SecureRandom.hex(32)
    self.status ||= STATUS_PENDING
  end

  def update_slug
    self.slug = name.parameterize if name.present?
  end
end
