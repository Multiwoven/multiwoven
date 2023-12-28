# frozen_string_literal: true

module Multiwoven
  module Integrations
    VERSION = "0.1.0"

    ENABLED_SOURCES = %w[
      Snowflake
      Redshift
    ].freeze

    ENABLED_DESTINATIONS = %w[
      Klaviyo
    ].freeze
  end
end
