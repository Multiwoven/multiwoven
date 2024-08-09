# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.7.9"
=======
    VERSION = "0.7.7"
>>>>>>> 38666561 (chore(CE): add request reponse log for Airtable (#342))

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
    ].freeze
  end
end
