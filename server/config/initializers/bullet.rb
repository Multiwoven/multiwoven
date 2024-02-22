# config/initializers/bullet.rb

if Rails.env.development? || Rails.env.test?
  Rails.application.config.after_initialize do
    Bullet.enable = true             # Enable Bullet gem
    Bullet.rails_logger = true       # Add Bullet warnings and logs to Rails logger
    Bullet.console = true            # Log warnings to the console (useful for API testing tools)
    Bullet.raise = false             # Raise an error if an n+1 query occurs (useful in test environments)
    # Omit Bullet.add_footer and Bullet.alert as they are not applicable for API-only apps
  end
end
