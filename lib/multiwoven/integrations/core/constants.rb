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
      MAIN_BRANCH_SHA = Git.ls_remote("https://github.com/Multiwoven/multiwoven-integrations")["head"][:sha]

      SNOWFLAKE_DRIVER_PATH = ENV["SNOWFLAKE_DRIVER_PATH"] || SNOWFLAKE_MAC_DRIVER_PATH

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

      # HTTP
      HTTP_GET = "GET"
      HTTP_POST = "POST"
      HTTP_PUT = "PUT"
      HTTP_DELETE = "DELETE"
    end
  end
end
