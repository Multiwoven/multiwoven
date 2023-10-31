# frozen_string_literal: true

json.array! @connectors do |connector|
  json.partial! "api/v1/core_models/connector", formats: [:json], connector:
end
