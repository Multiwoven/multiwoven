# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    module Constants
      # CONFIG
      INTEGRATIONS_PATH = File.join(
        Gem.loaded_specs["multiwoven-integrations"].full_gem_path,
        "/lib/multiwoven/integrations"
      )
      META_DATA_PATH = "config/meta.json"
      CONNECTOR_SPEC_PATH = "config/spec.json"
      CATALOG_SPEC_PATH   = "config/catalog.json"
      SNOWFLAKE_MAC_DRIVER_PATH = "/opt/snowflake/snowflakeodbc/lib/universal/libSnowflake.dylib"
      DATABRICKS_MAC_DRIVER_PATH = "/Library/simba/spark/lib/libsparkodbc_sb64-universal.dylib"
      MAIN_BRANCH_SHA = Git.ls_remote("https://github.com/Multiwoven/multiwoven-integrations")["head"][:sha]

      SNOWFLAKE_DRIVER_PATH = ENV["SNOWFLAKE_DRIVER_PATH"] || SNOWFLAKE_MAC_DRIVER_PATH
      DATABRICKS_DRIVER_PATH = ENV["DATABRICKS_DRIVER_PATH"] || DATABRICKS_MAC_DRIVER_PATH

      JSON_SCHEMA_URL = "https://json-schema.org/draft-07/schema#"

      # CONNECTORS
      KLAVIYO_AUTH_ENDPOINT = "https://a.klaviyo.com/api/lists/"
      KLAVIYO_AUTH_PAYLOAD = {
        data: {
          type: "list",
          attributes: {
            name: "THIS IS REQUIRED"
          }
        }
      }.freeze

      FACEBOOK_AUDIENCE_GET_ALL_ACCOUNTS = "https://graph.facebook.com/v18.0/me/adaccounts?fields=id,name"

      AIRTABLE_URL_BASE = "https://api.airtable.com/v0/"
      AIRTABLE_BASES_ENDPOINT = "https://api.airtable.com/v0/meta/bases"
      AIRTABLE_GET_BASE_SCHEMA_ENDPOINT = "https://api.airtable.com/v0/meta/bases/{baseId}/tables"

      # HTTP
      HTTP_GET = "GET"
      HTTP_POST = "POST"
      HTTP_PUT = "PUT"
      HTTP_DELETE = "DELETE"

      # google sheets
      GOOGLE_SHEETS_SCOPE = "https://www.googleapis.com/auth/drive"
      GOOGLE_SPREADSHEET_ID_REGEX = %r{/d/([-\w]{20,})/}.freeze
    end
  end
end
