# frozen_string_literal: true

FactoryBot.define do
  factory :knowledge_base_file, class: "Agents::KnowledgeBaseFile" do
    association :knowledge_base, factory: :knowledge_base
    name { "My Knowledge Base File" }
    size { 100 }
    workflow_enabled { false }
    upload_status { :processing }
  end
end
