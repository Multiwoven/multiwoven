# frozen_string_literal: true

module Utils
  module JwtSecret
    class MissingError < StandardError; end

    def self.fetch(env: ENV, rails_env: Rails.env)
      env["JWT_SECRET"].presence || fallback(rails_env)
    end

    def self.fallback(rails_env)
      raise MissingError, "JWT_SECRET must be set in production" if rails_env.production?

      Rails.application.secret_key_base
    end
    private_class_method :fallback
  end
end
