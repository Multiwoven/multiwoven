# frozen_string_literal: true

class DataApp < ApplicationRecord
  before_validation :generate_data_app_token, on: :create
  validates :workspace_id, presence: true
  validates :status, presence: true
  validates :name, presence: true
  validates :data_app_token, presence: true, uniqueness: true

  enum :status, %i[inactive active draft]
  enum :rendering_type, %i[embed no_code assistant]

  belongs_to :workspace
  has_many :visual_components, dependent: :destroy
  has_many :models, through: :visual_components
  has_many :feedbacks, through: :visual_components
  has_many :data_app_sessions, dependent: :destroy
  has_many :chat_messages, through: :visual_components
  has_many :message_feedbacks, through: :visual_components

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :draft
  end

  def generate_data_app_token
    self.data_app_token = generate_unique_token
  end

  def generate_unique_token
    loop do
      token = Devise.friendly_token
      break token unless DataApp.exists?(data_app_token: token)
    end
  end
end
