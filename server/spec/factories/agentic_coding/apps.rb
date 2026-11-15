# frozen_string_literal: true

FactoryBot.define do
  factory :agentic_coding_app, class: "AgenticCoding::App" do
    association :workspace
    association :user
    name { "MyString" }
    description { "MyText" }
    status { :draft }
  end
end
