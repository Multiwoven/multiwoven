# frozen_string_literal: true

json.array! @syncs do |sync|
  json.partial! "api/v1/core_models/sync", formats: [:json], sync:
end