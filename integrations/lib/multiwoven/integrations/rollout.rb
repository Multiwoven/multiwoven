# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.29.0"
=======
    VERSION = "0.30.0"
>>>>>>> c194e6e3 (feat(CE): Add Firecrawl Source Connector (#1167))

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
      DatabricksModel
      AwsSagemakerModel
      VertexModel
      HttpModel
      OpenAI
      Sftp
      WatsonxAi
      WatsonxData
      Anthropic
      AwsBedrockModel
      GenericOpenAI
      IntuitQuickBooks
      PineconeDB
      Qdrant
      Firecrawl
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
      MicrosoftSql
      Mailchimp
      AISDataStore
      AmazonS3
      MicrosoftDynamics
      Qdrant
      PineconeDB
    ].freeze
  end
end
