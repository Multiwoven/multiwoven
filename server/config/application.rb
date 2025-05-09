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
require_relative '../app/middleware/multiwoven_server/request_response_logger'

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
    config.autoload_paths << Rails.root.join('app', 'middleware')
    config.autoload_paths << Rails.root.join('app', 'contracts')
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.middleware.insert_before Rails::Rack::Logger, MultiwovenServer::QuietLogger
    config.middleware.use MultiwovenServer::RequestResponseLogger

    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    host = ENV.fetch('SMTP_HOST', 'squared.ai')
    config.action_mailer.default_url_options = { host: host }
    brand_name = ENV['BRAND_NAME'].presence || 'AI Squared'
    smtp_sender_email = ENV['SMTP_SENDER_EMAIL'].presence || 'ai2-mailer@squared.ai'
    config.x.mail_from = "#{brand_name} <#{smtp_sender_email}>"
    config.action_mailer.smtp_settings = {
      address:  ENV['SMTP_ADDRESS'],
      port: ENV.fetch('SMTP_PORT', '587'),
      authentication: :login,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      enable_starttls_auto: true
    }
    config.active_model.i18n_customize_full_message = true
  end
end