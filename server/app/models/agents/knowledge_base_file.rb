# frozen_string_literal: true

module Agents
  class KnowledgeBaseFile < ApplicationRecord
    belongs_to :knowledge_base, class_name: "KnowledgeBase"
    has_one_attached :file

    enum :upload_status, { processing: 0, processed: 1, failed: 2 }

    validates :name, presence: true
    validates :size, presence: true
    validates :upload_status, presence: true
  end
end
