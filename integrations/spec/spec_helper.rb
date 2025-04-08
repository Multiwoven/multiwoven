# frozen_string_literal: true

require "webmock/rspec"

require "simplecov"
require "simplecov_json_formatter"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                  SimpleCov::Formatter::HTMLFormatter,
                                                                  SimpleCov::Formatter::JSONFormatter
                                                                ])

SimpleCov.start do
  add_filter "/spec/"
  add_group "Core", "/lib/multiwoven/integrations/core"
  add_group "Destination", "/lib/multiwoven/integrations/destination"
  add_group "Protocol", "/lib/multiwoven/integrations/protocol"
  add_group "Source", "/lib/multiwoven/integrations/source"
end

require "multiwoven/integrations"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
