# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.35.0"
=======
    VERSION = "0.37.0"
>>>>>>> 42efd6924 (feat(CE): Add One drive connector (#1987))

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
      Odoo
      GoogleDrive
      Http
<<<<<<< HEAD
=======
      Aisquared
      OneDrive
>>>>>>> 42efd6924 (feat(CE): Add One drive connector (#1987))
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
      Odoo
      Weaviate
    ].freeze
  end
end
