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

      DATABRICKS_HEALTH_URL  = "https://%<databricks_host>s/api/2.0/serving-endpoints/%<endpoint_name>s"
      DATABRICKS_SERVING_URL = "https://%<databricks_host>s/serving-endpoints/%<endpoint_name>s/invocations"

      GOOGLE_VERTEX_ENDPOINT_SERVICE_URL = "%<region>s-aiplatform.googleapis.com"
      GOOGLE_VERTEX_MODEL_NAME = "projects/%<project_id>s/locations/%<region>s/endpoints/%<endpoint_id>s"

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
    end
  end
end
