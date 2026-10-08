# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.35.3"
=======
    VERSION = "0.43.0"
>>>>>>> 077c3d8de (chore(CE): Add SQL Server as Source (#2265))

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
      MicrosoftDynamics
      EpicFhir
      SqlServer
>>>>>>> 077c3d8de (chore(CE): Add SQL Server as Source (#2265))
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
