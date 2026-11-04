# frozen_string_literal: true

module SpendingLimits
  class SpendLimitExceeded < StandardError
    CODE = "spend_limit_exceeded"
    PUBLIC_MESSAGE = "This service is temporarily unavailable. Please try again later."

    SCOPE_LABELS = {
      "workspace" => "Workspace",
      "workflow" => "AI Workflows",
      "data_app" => "Data Apps",
      "user" => "Users",
      "role" => "Roles"
    }.freeze

    attr_reader :decision

    def self.blocked?(metadata)
      return false unless metadata.is_a?(Hash)

      (metadata[:code] || metadata["code"]) == CODE
    end

    def initialize(decision = nil)
      @decision = decision
      super(build_message)
    end

    def limit
      decision&.limit
    end

    def resets_at
      decision&.resets_at
    end

    def scope
      limit&.scope_type.to_s.presence
    end

    def exhausted
      decision&.exhausted.to_s.presence
    end

    # No row id: this body reaches callers who may hold no spending_limit permission.
    def metadata
      {
        code: CODE,
        scope:,
        exhausted:,
        resets_at: resets_at&.utc&.iso8601
      }.compact
    end

    def public_message
      PUBLIC_MESSAGE
    end

    private

    def build_message
      return PUBLIC_MESSAGE if limit.nil?

      "Spend limit '#{limit.name}' (#{qualifiers}) is used up for the current period."
    end

    def qualifiers
      [SCOPE_LABELS[limit.scope_type.to_s] || limit.scope_type.to_s, provider_label].compact.join(", ")
    end

    def provider_label
      providers = Array(limit.providers).map(&:to_s).reject(&:empty?)
      return nil if providers.empty?

      providers.to_sentence
    end
  end
end
