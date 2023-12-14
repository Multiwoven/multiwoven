# frozen_string_literal: true

require "json"
require "dry-struct"
require "dry-schema"
require "dry-types"
require "odbc"
require "sequel"
require "byebug"
# Core
require_relative "integrations/version"
require_relative "integrations/core/constants"
require_relative "integrations/core/utils"
require_relative "integrations/protocol/protocol"
require_relative "integrations/core/base_connector"
require_relative "integrations/core/source_connector"
require_relative "integrations/core/destination_connector"

# Source
require_relative "integrations/source/snowflake/client"

module Multiwoven
  module Integrations
    class Error < StandardError; end
    # Your code goes here...
  end
end
