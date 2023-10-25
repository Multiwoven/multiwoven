# frozen_string_literal: true

FactoryBot.define do
  factory :sync do
    workspace_id { 1 }
    source_id { 1 }
    model_id { 1 }
    destination_id { 1 }
    configuration { "" }
    source_catalog_id { 1 }
    schedule_type { 1 }
    schedule_data { "" }
    status { 1 }
  end
end
