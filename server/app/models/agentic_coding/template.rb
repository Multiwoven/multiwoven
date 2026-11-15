# frozen_string_literal: true

module AgenticCoding
  class Template < ApplicationRecord
    # Defaults for legacy seed migrations that omit slug on create.
    DEFAULT_SLUGS = {
      "Customer Support" => "customer-support",
      "KPI Monitoring Dashboard" => "kpi-monitoring",
      "Sales Dashboard" => "sales-dashboard",
      "Chat with Data" => "chat-with-data"
    }.freeze

    has_many :apps, class_name: "AgenticCoding::App",
                    dependent: :nullify,
                    inverse_of: :template

    enum status: {
      draft: 0,
      active: 1,
      archived: 2
    }

    before_validation :assign_default_slug, if: -> { slug.blank? }

    validates :slug, presence: true, uniqueness: true
    validates :name, presence: true, uniqueness: true
    validates :image_id, presence: true
    validates :status, presence: true

    scope :active_templates, -> { where(status: :active) }

    private

    def assign_default_slug
      self.slug = DEFAULT_SLUGS[name] || name&.parameterize.presence
    end
  end
end
