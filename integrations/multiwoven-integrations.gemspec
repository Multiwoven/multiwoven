# frozen_string_literal: true

require_relative "lib/multiwoven/integrations/rollout"

Gem::Specification.new do |spec|
  spec.name = "multiwoven-integrations"
  spec.version = Multiwoven::Integrations::VERSION
  spec.authors = ["Subin T P"]
  spec.email = ["subin@multiwoven.com"]

  spec.summary = "Integration suite for open source reverse ETL platform"
  spec.description = "Multiwoven Integrations is a comprehensive Ruby gem designed to facilitate seamless connectivity between various data sources and SaaS platforms."

  spec.homepage = "https://www.multiwoven.com/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = nil
  spec.metadata["github_repo"] = "https://github.com/Multiwoven/multiwoven"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Multiwoven/multiwoven/tree/main/integrations"
  spec.metadata["changelog_uri"] = "https://github.com/Multiwoven/multiwoven/blob/main/integrations/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "async-websocket"
  spec.add_runtime_dependency "aws-sdk-athena"
  spec.add_runtime_dependency "csv"
  spec.add_runtime_dependency "dry-schema"
  spec.add_runtime_dependency "dry-struct"
  spec.add_runtime_dependency "dry-types"
  spec.add_runtime_dependency "git"
  spec.add_runtime_dependency "google-apis-sheets_v4"
  spec.add_runtime_dependency "google-cloud-bigquery"
  spec.add_runtime_dependency "hubspot-api-client"
  spec.add_runtime_dependency "iterable-api-client"
  spec.add_runtime_dependency "net-sftp"
  spec.add_runtime_dependency "pg"
  spec.add_runtime_dependency "rake"
  spec.add_runtime_dependency "restforce"
  spec.add_runtime_dependency "ruby-limiter"
  spec.add_runtime_dependency "ruby-odbc"
  spec.add_runtime_dependency "rubyzip"
  spec.add_runtime_dependency "sequel"
  spec.add_runtime_dependency "slack-ruby-client"
  spec.add_runtime_dependency "stripe"
  spec.add_runtime_dependency "zendesk_api"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov_json_formatter"
  spec.add_development_dependency "webmock"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
