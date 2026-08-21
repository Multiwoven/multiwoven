# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.35.2"
=======
    VERSION = "0.40.1"
>>>>>>> be9215ce8 (chore(CE): Update EPIC FHIR to handle "Another request for this same Client and Group is in progress." error (#2175))

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
