# frozen_string_literal: true

FactoryBot.define do
  factory :custom_visual_component_file do
    file_name { "sample_file.txt" }
    association :workspace
  end
end
