FactoryBot.define do
  factory :catalog do
    workspace_id { 1 }
    connector_id { 1 }
    catalog { "" }
    catalog_hash { 1 }
  end
end
