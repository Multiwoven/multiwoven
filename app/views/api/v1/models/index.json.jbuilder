# frozen_string_literal: true

json.array! @models do |model|
  json.partial! "api/v1/core_models/model", formats: [:json], model:
end
