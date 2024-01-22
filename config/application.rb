require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"
# config/application.rb
require_relative '../app/middleware/multiwoven_server/quiet_logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MultiwovenServer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
    config.require_master_key = false
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    # 
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Autoload paths
    config.autoload_paths << Rails.root.join('app', 'interactors')
    config.autoload_paths << Rails.root.join('app', 'temporal')
    config.autoload_paths += %W(#{config.root}/app/middleware)
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.insert_before Rails::Rack::Logger, MultiwovenServer::QuietLogger
    # email setup
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    host = ENV.fetch('SMTP_HOST', 'multiwoven.com') # Replace 'multiwoven.com' with SMTP_HOST value if needed
    config.action_mailer.default_url_options = { host: host }
    config.x.mail_from = %("Multiwoven" <noreply@multiwoven.com>)
    ActionMailer::Base.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV.fetch('SMTP_PORT', '587'), # '587' is the default value if SMTP_PORT is not set
      authentication: :plain,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
    }
  end
end