# frozen_string_literal: true

module AgenticCoding
  class App < ApplicationRecord
    belongs_to :workspace
    belongs_to :user

    has_many :sessions, class_name: "AgenticCoding::Session", dependent: :destroy, inverse_of: :agentic_coding_app
    has_many :prompts, class_name: "AgenticCoding::Prompt", dependent: :destroy, inverse_of: :agentic_coding_app
    has_many :deployments, class_name: "AgenticCoding::Deployment", dependent: :destroy, inverse_of: :agentic_coding_app

    enum status: {
      draft: 0,
      published: 1,
      archived: 2
    }

    validates :name, presence: true
    validates :status, presence: true
  end
end
