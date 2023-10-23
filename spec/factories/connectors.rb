FactoryBot.define do
  factory :connector do
    workspace_id { 1 }
    connector_type { 1 }
    connector_definition_id { 1 }
    configuration { "" }
    name { "MyString" }
  end
end
