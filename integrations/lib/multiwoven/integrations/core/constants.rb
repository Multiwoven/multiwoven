# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Constants
      # CONFIG
      META_DATA_PATH = "config/meta.json"
      CONNECTOR_SPEC_PATH = "config/spec.json"
      CATALOG_SPEC_PATH   = "config/catalog.json"
      SNOWFLAKE_MAC_DRIVER_PATH = "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib"
      DATABRICKS_MAC_DRIVER_PATH = "/Library/simba/spark/lib/libsparkodbc_sb64-universal.dylib"

      SNOWFLAKE_DRIVER_PATH = ENV["SNOWFLAKE_DRIVER_PATH"] || SNOWFLAKE_MAC_DRIVER_PATH
      DATABRICKS_DRIVER_PATH = ENV["DATABRICKS_DRIVER_PATH"] || DATABRICKS_MAC_DRIVER_PATH

      JSON_SCHEMA_URL = "https://json-schema.org/draft-07/schema#"

      # CONNECTORS
      INSTALL_HTTPFS_QUERY = ENV["INSTALL_HTTPFS_QUERY"] || "INSTALL HTTPFS; LOAD HTTPFS;"

      KLAVIYO_AUTH_ENDPOINT = "https://a.klaviyo.com/api/lists/"
      KLAVIYO_AUTH_PAYLOAD = {
        data: {
          type: "list",
          attributes: {
            name: "THIS IS REQUIRED"
          }
        }
      }.freeze

      ZENDESK_URL_SUFFIX = "zendesk.com/api/v2/"

      FACEBOOK_AUDIENCE_GET_ALL_ACCOUNTS = "https://graph.facebook.com/v18.0/me/adaccounts?fields=id,name"

      AIRTABLE_URL_BASE = "https://api.airtable.com/v0/"
      AIRTABLE_BASES_ENDPOINT = "https://api.airtable.com/v0/meta/bases"
      AIRTABLE_GET_BASE_SCHEMA_ENDPOINT = "https://api.airtable.com/v0/meta/bases/{baseId}/tables"

      MS_EXCEL_AUTH_ENDPOINT = "https://graph.microsoft.com/v1.0/me"
      MS_EXCEL_TABLE_ROW_WRITE_API = "https://graph.microsoft.com/v1.0/drives/%<drive_id>s/items/%<item_id>s/"\
      "workbook/worksheets/%<sheet_name>s/tables/%<table_name>s/rows"
      MS_EXCEL_TABLE_API = "https://graph.microsoft.com/v1.0/drives/%<drive_id>s/items/%<item_id>s/workbook/"\
      "worksheets/%<sheet_name>s/tables?$select=name"
      MS_EXCEL_FILES_API = "https://graph.microsoft.com/v1.0/drives/%<drive_id>s/root/children"
      MS_EXCEL_WORKSHEETS_API = "https://graph.microsoft.com/v1.0/drives/%<drive_id>s/items/%<item_id>s/"\
      "workbook/worksheets"
      MS_EXCEL_SHEET_RANGE_API = "https://graph.microsoft.com/v1.0/drives/%<drive_id>s/items/%<item_id>s/"\
      "workbook/worksheets/%<sheet_name>s/range(address='A1:Z1')/usedRange?$select=values"
      MS_DYNAMICS_WHOAMI_API = "https://%<instance_url>s.crm.dynamics.com/api/data/v%<api_version>s/WhoAmI"
      MS_DYNAMICS_REST_API = "https://%<instance_url>s.crm.dynamics.com/api/data/v%<api_version>s/%<entity>s"

      DATABRICKS_HEALTH_URL  = "https://%<databricks_host>s/api/2.0/serving-endpoints/%<endpoint_name>s"
      DATABRICKS_SERVING_URL = "https://%<databricks_host>s/serving-endpoints/%<endpoint_name>s/invocations"

      GOOGLE_VERTEX_ENDPOINT_SERVICE_URL = "%<region>s-aiplatform.googleapis.com"
      GOOGLE_VERTEX_MODEL_NAME = "projects/%<project_id>s/locations/%<region>s/endpoints/%<endpoint_id>s"

      WATSONX_HEALTH_DEPLOYMENT_URL = "https://%<region>s.ml.cloud.ibm.com/ml/v4/deployments?version=%<version>s"
      WATSONX_PREDICTION_DEPLOYMENT_URL = "https://%<region>s.ml.cloud.ibm.com/ml/v4/deployments/%<deployment_id>s/predictions?version=%<version>s"
      WATSONX_GENERATION_DEPLOYMENT_URL = "https://%<region>s.ml.cloud.ibm.com/ml/v1/deployments/%<deployment_id>s/text/generation?version=%<version>s"
      WATSONX_STREAM_DEPLOYMENT_URL = "https://%<region>s.ml.cloud.ibm.com/ml/v1/deployments/%<deployment_id>s/text/generation_stream?version=%<version>s"

      WATSONX_DATA_QUERIES_URL = "https://%<region>s.lakehouse.cloud.ibm.com/lakehouse/api/v2/queries/execute/%<engine_id>s"

      # HTTP
      HTTP_GET = "GET"
      HTTP_POST = "POST"
      HTTP_PUT = "PUT"
      HTTP_DELETE = "DELETE"
      HTTP_PATCH = "PATCH"

      # google sheets
      GOOGLE_SHEETS_SCOPE = "https://www.googleapis.com/auth/drive"
      GOOGLE_SPREADSHEET_ID_REGEX = %r{/d/([-\w]{20,})/}.freeze

      OPEN_AI_URL = "https://api.openai.com/v1/chat/completions"
      ANTHROPIC_URL = "https://api.anthropic.com/v1/messages"

      # Bedrock Models
      MISTRAL_AI_MODEL = %w[
        mistral.mistral-large-2402-v1:0
        mistral.mistral-7b-instruct-v0:2
        mistral.mixtral-8x7b-instruct-v0:1
        mistral.mistral-small-2402-v1:0
      ].freeze
    end
  end
end
