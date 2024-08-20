# frozen_string_literal: true

module Multiwoven
  module Integrations
    VERSION = "0.8.5"

    ENABLED_SOURCES = %w[
      Snowflake
      Redshift
      Bigquery
      Postgresql
      Databricks
      SalesforceConsumerGoodsCloud
      AwsAthena
      Clickhouse
      AmazonS3
      MariaDB
      Oracle
    ].freeze

    ENABLED_DESTINATIONS = %w[
      Klaviyo
      SalesforceCrm
      FacebookCustomAudience
      Slack
      Hubspot
      GoogleSheets
      Airtable
      Stripe
      SalesforceConsumerGoodsCloud
      Sftp
      Postgresql
      Zendesk
      Http
      Iterable
      MariaDB
      DatabricksLakehouse
      Oracle
      MicrosoftExcel
    ].freeze
  end
end
