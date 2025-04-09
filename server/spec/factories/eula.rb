# frozen_string_literal: true

FactoryBot.define do
  factory :eula do
    file_name { "sample_file.pdf" }
    status { 0 }
    association :organization
  end
end
