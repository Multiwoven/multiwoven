# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors
<<<<<<< HEAD
=======
#
# CORS_ALLOWED_ORIGINS accepts a comma-separated list. Each entry can be:
#   - A full origin, e.g. "https://app.squared.ai"
#   - A wildcard subdomain, e.g. "*.squared.ai" (matches any subdomain, not the bare domain)
#   - The magic token "localhost" (matches http(s)://localhost and http://127.0.0.1 on any port)
#
# If unset, defaults to "*.squared.ai,localhost".

module CorsOriginParser
  DEFAULT = "*.squared.ai,*.aisquared.ai,localhost"
  WILDCARD_SUBDOMAIN = /\A\*\.(?<domain>[a-z0-9.-]+)\z/i

  def self.parse(raw)
    raw.to_s.split(",").map(&:strip).reject(&:empty?).flat_map do |value|
      if value == "localhost"
        [%r{\Ahttps?://localhost(:\d+)?\z}, %r{\Ahttp://127\.0\.0\.1(:\d+)?\z}]
      elsif (match = value.match(WILDCARD_SUBDOMAIN))
        [%r{\Ahttps?://([a-z0-9-]+\.)+#{Regexp.escape(match[:domain])}\z}i]
      else
        [value]
      end
    end
  end

  def self.configured_matchers
    parse(ENV.fetch("CORS_ALLOWED_ORIGINS", DEFAULT))
  end
end
>>>>>>> bb0ec6d75 (chore(CE): added clickjacking frame ancestors header for security (#2124))

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
<<<<<<< HEAD
    origins ENV.fetch("CORS_ALLOWED_ORIGINS", "*")
=======
    origins(*CorsOriginParser.configured_matchers)
>>>>>>> bb0ec6d75 (chore(CE): added clickjacking frame ancestors header for security (#2124))

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
