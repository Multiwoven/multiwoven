# frozen_string_literal: true

class EmbeddingModel < ApplicationRecord
  enum status: { inactive: 0, active: 1 }

  validates :mode, presence: true
  validates :models, presence: true
end
