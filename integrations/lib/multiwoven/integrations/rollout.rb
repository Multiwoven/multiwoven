# frozen_string_literal: true

module Multiwoven
  module Integrations
    VERSION = "0.1.31"

    ENABLED_SOURCES = %w[
      Snowflake
      Redshift
      Bigquery
      Postgresql
      Databricks
    ].freeze

    ENABLED_DESTINATIONS = %w[
      Klaviyo
      SalesforceCrm
      FacebookCustomAudience
      Slack
      Hubspot
    ].freeze
  end
end
