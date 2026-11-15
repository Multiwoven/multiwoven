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

  # Service.connectors memoizes its build, so a stubbed ENABLED_SOURCES would
  # otherwise leak into every example that runs after it. Building a spec also
  # reaches OpenRouter for live model metadata, and WebMock refuses with an
  # Exception the catalog's own rescue does not catch.
  config.before do
    Multiwoven::Integrations::Service.reset_connectors!
    Multiwoven::Integrations::Core::OpenRouterCatalog.reset!
    stub_request(:get, Multiwoven::Integrations::Core::OpenRouterCatalog::MODELS_URL)
      .to_return(status: 200, body: { data: [] }.to_json)
  end
end
