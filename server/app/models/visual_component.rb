# frozen_string_literal: true

class VisualComponent < ApplicationRecord
  validates :workspace_id, presence: true
  validates :component_type, presence: true
  validates :model_id, presence: true
  validates :data_app_id, presence: true

  enum :component_type, %i[pie bar data_table]

  belongs_to :workspace
  belongs_to :data_app
  belongs_to :model
end
