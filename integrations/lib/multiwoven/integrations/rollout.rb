# frozen_string_literal: true

module Multiwoven
  module Integrations
<<<<<<< HEAD
    VERSION = "0.35.3"
=======
    VERSION = "0.42.0"
>>>>>>> 03e00a685 (chore(CE): Add Mistral AI as AI/ML Source Connector (#2260))

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
<<<<<<< HEAD
=======
      GoogleGemini
      JohnSnowLabs
      AzureOpenAI
      Xai
      Groq
      OpenRouter
      MistralAi
>>>>>>> 03e00a685 (chore(CE): Add Mistral AI as AI/ML Source Connector (#2260))
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
