# frozen_string_literal: true

class CustomVisualComponentFile < ApplicationRecord
  has_one_attached :file

  belongs_to :workspace
end
