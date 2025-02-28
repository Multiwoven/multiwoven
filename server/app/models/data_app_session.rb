# frozen_string_literal: true

class DataAppSession < ApplicationRecord
  belongs_to :data_app
  belongs_to :workspace
  has_many :chat_messages, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true
  validates :data_app_id, :workspace_id, presence: true

  counter_culture :data_app

  before_create :set_times

  after_create :track_usage

  scope :active, -> { where("end_time IS NULL OR end_time > ?", Time.zone.now) }

  def expired?
    end_time.present? && end_time <= Time.zone.now
  end

  private

  def set_times
    self.start_time = Time.zone.now
    return if chat_bot_session?

    session_length_minutes = (ENV["DATA_SESSION_LENGTH_MINUTES"] || 10).to_i # Default to 10 minutes if not set
    self.end_time = start_time + session_length_minutes.minutes
  end

  # Data app contains only one visual component in case of chat bot
  def chat_bot_session?
    visual_components = data_app.visual_components
    visual_components.present? && visual_components.first&.chat_bot?
  end

  def track_usage
    subscription = workspace.organization.active_subscription
    return unless subscription

    # rubocop:disable Rails/SkipsModelValidations
    subscription.increment!(:data_app_sessions)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
