# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.2.0"

# Core
gem "aasm"
gem "annotate"
gem "aws-sdk"
gem "interactor", "~> 3.0"
gem "mw-ruby-odbc"

gem "multiwoven-integrations", "~> 0.1.1"

gem "pg", "~> 1.1"       # PostgreSQL Database
gem "puma", ">= 5.0"     # Web server
gem "rails", "~> 7.1.1"  # Core Rails gem

# API Support
gem "jbuilder"
gem "jwt"
gem "kaminari"
gem "rack-cors"

# AuthN & AuthZ
gem "devise"
gem "devise-jwt"

# Utilities
gem "activerecord_json_validator", "~> 2.1.0"
gem "bootsnap", require: false # Reduces boot time
gem "tzinfo-data", platforms: %i[windows jruby] # Timezone data

# Debugging
group :development, :test do
  gem "byebug", platforms: %i[mri windows] # Debugging tool
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails"
  gem "shoulda-matchers", "~> 5.0"
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
end

# Development Environment
group :development do
  # Add development-only gems here. For example:
  # gem "spring"  # Speeds up Rails commands
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
end

# Production Environment
group :production do
  # Add production-only gems here.
  gem "redis", "~> 4.0"
end

# API Serialization & Pagination
# Uncomment as needed:
# gem "fast_jsonapi"  # Efficient JSON serialization
# gem "kaminari"      # Pagination

# Authentication & Authorization
# Uncomment as needed:
# gem "devise"        # Authentication
# gem "devise-jwt"    # JWT for API
# gem "cancancan"     # Authorization

# Optional Enhancements
# Uncomment as needed:
# gem "rack-cors"     # CORS handling
# gem "image_processing", "~> 1.2"  # For image variants if you decide to use Active Storage

# NOTE: Removed unused or commented-out gems for better readability.
