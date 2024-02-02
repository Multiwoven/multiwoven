# frozen_string_literal: true

module Multiwoven
  module Integrations
    VERSION = "0.1.10"

    ENABLED_SOURCES = %w[
      Snowflake
      Redshift
      Bigquery
    ].freeze

    ENABLED_DESTINATIONS = %w[
      Klaviyo
      SalesforceCrm
      FacebookCustomAudience
      Slack
    ].freeze
  end
end
