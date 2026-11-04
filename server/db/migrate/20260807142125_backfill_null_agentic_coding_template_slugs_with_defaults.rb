# frozen_string_literal: true

# Backfills null/blank slugs on existing agentic_coding_templates rows.
# Fresh seed creates (which omit slug) are handled by
# AgenticCoding::Template#assign_default_slug — this migration does not seed.
class BackfillNullAgenticCodingTemplateSlugsWithDefaults < ActiveRecord::Migration[7.2]
  DEFAULT_SLUGS = {
    "Customer Support" => "customer-support",
    "KPI Monitoring Dashboard" => "kpi-monitoring",
    "Sales Dashboard" => "sales-dashboard",
    "Chat with Data" => "chat-with-data"
  }.freeze

  def up
    return unless column_exists?(:agentic_coding_templates, :slug)

    safety_assured do
      DEFAULT_SLUGS.each do |name, slug|
        execute <<~SQL.squish
          UPDATE agentic_coding_templates
          SET slug = #{connection.quote(slug)}
          WHERE name = #{connection.quote(name)}
            AND (slug IS NULL OR slug = '')
        SQL
      end

      # Any remaining null/blank slugs get a parameterized name default.
      execute <<~SQL.squish
        UPDATE agentic_coding_templates
        SET slug = CONCAT(trim(both '-' from regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g')), '-', id)
        WHERE (slug IS NULL OR slug = '')
          AND name IS NOT NULL
          AND name <> ''
      SQL
    end
  end

  def down
    # Intentionally left blank: canonical slugs should remain once assigned.
  end
end
