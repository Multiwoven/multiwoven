# frozen_string_literal: true

require_relative "../../../config/application"
require "temporal/worker"

# Load the Rails environment
Rails.application.require_environment!

NewRelic::Agent.manual_start(license_key: ENV["NEW_RELIC_KEY"]) if ENV["NEW_RELIC_KEY"].present?
