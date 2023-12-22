# frozen_string_literal: true

require "json"
require "dry-struct"
require "dry-schema"
require "dry-types"
require "odbc"
require "sequel"
require "byebug"
require "net/http"
require "uri"
require "active_support/core_ext/hash/indifferent_access"

# Core
require_relative "integrations/version"
require_relative "integrations/core/constants"
require_relative "integrations/core/utils"
require_relative "integrations/protocol/protocol"
require_relative "integrations/core/base_connector"
require_relative "integrations/core/source_connector"
require_relative "integrations/core/destination_connector"
require_relative "integrations/core/http_client"

# Source
require_relative "integrations/source/snowflake/client"

# Destination
require_relative "integrations/destination/klaviyo/client"

module Multiwoven
  module Integrations
    class Error < StandardError; end
    # Your code goes here...
  end
end
