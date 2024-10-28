# frozen_string_literal: true

class DataAppSession < ApplicationRecord
  belongs_to :data_app
  belongs_to :workspace
  validates :session_id, presence: true, uniqueness: true
  validates :data_app_id, :workspace_id, presence: true

  before_create :set_times

  scope :active, -> { where("end_time IS NULL OR end_time > ?", Time.zone.now) }

  def expired?
    end_time.present? && end_time <= Time.zone.now
  end

  private

  def set_times
    self.start_time = Time.zone.now
    session_length_minutes = (ENV["DATA_SESSION_LENGTH_MINUTES"] || 10).to_i # Default to 10 minutes if not set
    self.end_time = start_time + session_length_minutes.minutes
  end
end
